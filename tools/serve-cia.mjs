// Serves a .cia on the local network so the 3DS can install it from FBI's
// "Remote Install" (Scan QR Code) — the QR just holds this URL.
//
//   node tools/serve-cia.mjs [port] [file]
//
// Defaults: port 8000, DreamFTP.cia at the repository root. Ctrl+C stops it.
// Windows may ask to let Node.js through the firewall the first time: allow it
// on private networks, or the 3DS can't reach the PC.

import { createServer } from "node:http";
import { createReadStream, statSync } from "node:fs";
import { networkInterfaces } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const port = Number(process.argv[2] ?? 8000);
const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const file = resolve(process.argv[3] ?? join(root, "DreamFTP.cia"));
const name = file.split(/[\\/]/).pop();

let size;
try {
    size = statSync(file).size;
} catch {
    console.error(`missing ${file}`);
    process.exit(1);
}

const server = createServer((req, res) => {
    if (req.method !== "GET" && req.method !== "HEAD") {
        res.writeHead(405, { Allow: "GET, HEAD" }).end();
        return;
    }
    // a client that reconnects can ask for the rest of the file
    const range = /^bytes=(\d+)-(\d*)$/.exec(req.headers.range ?? "");
    if (range) {
        const start = Number(range[1]);
        const end = range[2] ? Math.min(Number(range[2]), size - 1) : size - 1;
        if (start >= size || start > end) {
            res.writeHead(416, { "Content-Range": `bytes */${size}` }).end();
            return;
        }
        res.writeHead(206, {
            "Content-Type": "application/octet-stream",
            "Content-Length": end - start + 1,
            "Content-Range": `bytes ${start}-${end}/${size}`,
            "Accept-Ranges": "bytes",
        });
        if (req.method === "HEAD") return res.end();
        createReadStream(file, { start, end }).pipe(res);
        return;
    }
    res.writeHead(200, {
        "Content-Type": "application/octet-stream",
        "Content-Length": size,
        "Accept-Ranges": "bytes",
    });
    if (req.method === "HEAD") return res.end();
    createReadStream(file).pipe(res);
});

server.listen(port, "0.0.0.0", () => {
    const addresses = Object.values(networkInterfaces())
        .flat()
        .filter((a) => a && a.family === "IPv4" && !a.internal)
        .map((a) => a.address);
    console.log(`${name}  ${(size / 1024 / 1024).toFixed(2)} MB`);
    for (const ip of addresses.length ? addresses : ["127.0.0.1"]) {
        console.log(`  http://${ip}:${port}/${encodeURIComponent(name)}`);
    }
    console.log("scan that URL in FBI: Remote Install, Scan QR Code");
});
