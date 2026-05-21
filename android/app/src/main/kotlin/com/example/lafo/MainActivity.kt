package com.example.dinoshare

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "dinoshare/picker"
        private const val PICK_CODE = 0x4C61  // "La"
        private const val PICK_DIR_CODE = 0x4C62
    }

    private var pendingResult: MethodChannel.Result? = null

    // Keeps ParcelFileDescriptors alive until the next pick session starts.
    // Each PFD must stay open until Dart has had a chance to open the
    // /proc/self/fd/{n} path; after that the Dart RandomAccessFile holds
    // its own fd and the original PFD is no longer needed.
    private val openPfds = mutableListOf<ParcelFileDescriptor>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pick" -> launchPicker(result)
                    "pickDirectory" -> launchDirectoryPicker(result)
                    "readUriBytes" -> readUriBytes(call.argument<String>("uri"), result)
                    "openUri" -> openUri(call.argument<String>("uri"), result)
                    "closeAll" -> { closeAll(); result.success(null) }
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun launchDirectoryPicker(result: MethodChannel.Result) {
        if (pendingResult != null) { result.success(null); return }
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }
        startActivityForResult(intent, PICK_DIR_CODE)
    }

    private fun handleDirectoryResult(resultCode: Int, data: Intent?) {
        val result = pendingResult ?: return
        pendingResult = null
        if (resultCode != Activity.RESULT_OK || data == null || data.data == null) {
            result.success(null)
            return
        }
        val treeUri = data.data!!
        try {
            contentResolver.takePersistableUriPermission(
                treeUri, Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
        } catch (_: Exception) { }

        Thread {
            try {
                val treeDocId = DocumentsContract.getTreeDocumentId(treeUri)
                val rootDocUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, treeDocId)
                val folderName = queryDisplayName(rootDocUri)
                    ?: treeDocId.split("/").lastOrNull()
                    ?: "Folder"
                val files = mutableListOf<Map<String, Any?>>()
                listFilesRecursive(treeUri, treeDocId, treeDocId, "", files)
                val resultPayload = mapOf(
                    "topLevelName" to folderName,
                    "treeUri" to treeUri.toString(),
                    "files" to files,
                )
                runOnUiThread { result.success(resultPayload) }
            } catch (_: Exception) {
                runOnUiThread { result.success(null) }
            }
        }.start()
    }

    private fun listFilesRecursive(
        treeUri: Uri,
        rootDocId: String,
        parentDocId: String,
        relDir: String,
        files: MutableList<Map<String, Any?>>,
        depth: Int = 0,
    ) {
        if (depth > 50) return
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, parentDocId)
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
        )
        try {
            contentResolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
                val idIdx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
                if (idIdx < 0) return
                val nameIdx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                val mimeIdx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_MIME_TYPE)
                val sizeIdx = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_SIZE)
                while (cursor.moveToNext()) {
                    val docId = cursor.getString(idIdx) ?: continue
                    val name = if (nameIdx >= 0) cursor.getString(nameIdx) ?: "file" else "file"
                    val mime = if (mimeIdx >= 0) cursor.getString(mimeIdx) ?: "" else ""
                    val size = if (sizeIdx >= 0 && !cursor.isNull(sizeIdx)) cursor.getLong(sizeIdx) else 0L
                    if (DocumentsContract.Document.MIME_TYPE_DIR == mime) {
                        val childRelDir = if (relDir.isEmpty()) name else "$relDir/$name"
                        listFilesRecursive(treeUri, rootDocId, docId, childRelDir, files, depth + 1)
                    } else {
                        try {
                            val docUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
                            val pfd = contentResolver.openFileDescriptor(docUri, "r") ?: continue
                            synchronized(openPfds) { openPfds.add(pfd) }
                            val path = "/proc/self/fd/${pfd.fd}"
                            files.add(mapOf(
                                "path" to path,
                                "uri" to docUri.toString(),
                                "name" to name,
                                "size" to size,
                                "relDir" to relDir,
                            ))
                        } catch (_: Exception) { }
                    }
                }
            }
        } catch (_: Exception) { }
    }

    @Suppress("DEPRECATION")
    private fun launchPicker(result: MethodChannel.Result) {
        if (pendingResult != null) { result.success(null); return }
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }
        startActivityForResult(intent, PICK_CODE)
    }

    @Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_DIR_CODE) {
            handleDirectoryResult(resultCode, data)
            return
        }
        if (requestCode != PICK_CODE) return
        val result = pendingResult ?: return
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(null)
            return
        }

        val uris = mutableListOf<Uri>()
        data.clipData?.let { clip ->
            for (i in 0 until clip.itemCount) uris.add(clip.getItemAt(i).uri)
        } ?: data.data?.let { uris.add(it) }

        val files = mutableListOf<Map<String, Any?>>()
        for (uri in uris) {
            try {
                try {
                    contentResolver.takePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
                } catch (_: Exception) { }
                val pfd = contentResolver.openFileDescriptor(uri, "r") ?: continue
                openPfds.add(pfd)
                val (name, size) = queryMeta(uri)
                files.add(mapOf(
                    "path" to "/proc/self/fd/${pfd.fd}",
                    "uri" to uri.toString(),
                    "name" to name,
                    "size" to size,
                ))
            } catch (_: Exception) { }
        }
        result.success(files)
    }

    private fun queryMeta(uri: Uri): Pair<String, Long> {
        var name = uri.lastPathSegment ?: "file"
        var size = 0L
        try {
            contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
                null, null, null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    name = cursor.getString(0) ?: name
                    size = cursor.getLong(1)
                }
            }
        } catch (_: Exception) { }
        return name to size
    }

    private fun queryDisplayName(uri: Uri): String? {
        try {
            val projection = arrayOf(OpenableColumns.DISPLAY_NAME)
            contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    return cursor.getString(0)
                }
            }
        } catch (_: Exception) { }
        return null
    }

    private fun closeAll() {
        synchronized(openPfds) {
            openPfds.forEach { try { it.close() } catch (_: Exception) { } }
            openPfds.clear()
        }
    }

    private fun readUriBytes(uriString: String?, result: MethodChannel.Result) {
        if (uriString.isNullOrBlank()) {
            result.success(null)
            return
        }
        try {
            val uri = Uri.parse(uriString)
            contentResolver.openInputStream(uri)?.use { input ->
                result.success(input.readBytes())
            } ?: result.success(null)
        } catch (e: Exception) {
            result.error("read_failed", e.message, null)
        }
    }

    private fun openUri(uriString: String?, result: MethodChannel.Result) {
        if (uriString.isNullOrBlank()) {
            result.success(false)
            return
        }
        try {
            val uri = Uri.parse(uriString)
            val mime = contentResolver.getType(uri) ?: "*/*"
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mime)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(intent, null))
            result.success(true)
        } catch (e: Exception) {
            result.error("open_failed", e.message, null)
        }
    }
}
