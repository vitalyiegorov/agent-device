// Scratch evidence tool, not part of the repo. MODE=stub answers locally; MODE=relay forwards to the real gateway and logs.
import http from 'node:http';
import fs from 'node:fs';
const { MODE, PORT, LOG, UPSTREAM, REUSED } = process.env;
const log = (o) => fs.appendFileSync(LOG, JSON.stringify(o) + '\n');
const redact = (p) => { const c = { ...p }; for (const k of ['token', 'daemonAuthToken']) delete c[k]; return c; };
const stub = (rpc) => {
  const p = rpc.params ?? {};
  if (rpc.method === 'agent_device.lease.allocate') {
    const lease = { leaseId: p.leaseId ?? 'stub-lease-1', tenantId: p.tenantId ?? p.tenant, runId: p.runId, backend: p.backend ?? p.leaseBackend,
      deviceKey: 'ios:mobile:STUB-SIMULATOR-UDID', device: { model: 'iPhone 17 Pro', osVersion: '26.2', physical: false, deviceMode: 'slim' } };
    return { ok: true, data: { lease, reused: REUSED === 'true' } };
  }
  if (rpc.method === 'agent_device.lease.release') return { ok: true, data: { released: true } };
  return { ok: false, error: { code: 'UNSUPPORTED_OPERATION', message: `stub gateway does not serve ${rpc.method}` } };
};
http.createServer(async (req, res) => {
  const chunks = []; for await (const c of req) chunks.push(c);
  const body = Buffer.concat(chunks);
  if (MODE === 'stub') {
    res.setHeader('content-type', 'application/json');
    if (req.url.endsWith('/health')) return res.end(JSON.stringify({ ok: true, service: 'STUB-gateway', instanceId: 'stub' }));
    const rpc = JSON.parse(body.toString());
    const result = stub(rpc);
    log({ dir: 'client->STUB', method: rpc.method, params: redact(rpc.params ?? {}) });
    log({ dir: 'STUB->client', method: rpc.method, result });
    return res.end(JSON.stringify({ jsonrpc: '2.0', id: rpc.id, result }));
  }
  const headers = { ...req.headers }; delete headers.host; delete headers['content-length'];
  const up = await fetch(UPSTREAM + req.url, { method: req.method, headers, body: req.method === 'GET' ? undefined : body });
  const text = Buffer.from(await up.arrayBuffer());
  if (req.url.endsWith('/rpc')) {
    try {
      const rpc = JSON.parse(body.toString());
      if (rpc.method?.includes('lease')) {
        log({ dir: 'client->gateway', method: rpc.method, params: redact(rpc.params ?? {}) });
        const r = JSON.parse(text.toString());
        log({ dir: 'gateway->client', method: rpc.method, http: up.status, lease: r.result?.data?.lease, released: r.result?.data?.released, error: r.error ?? r.result?.error });
      }
    } catch (e) { log({ dir: 'relay', logError: String(e) }); }
  }
  res.statusCode = up.status;
  const ct = up.headers.get('content-type'); if (ct) res.setHeader('content-type', ct);
  res.end(text);
}).listen(Number(PORT), '127.0.0.1', () => log({ dir: 'start', mode: MODE, upstream: MODE === 'relay' ? UPSTREAM : 'none: STUB' }));
