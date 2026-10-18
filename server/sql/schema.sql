CREATE TABLE IF NOT EXISTS organizations (
 id BIGSERIAL PRIMARY KEY, name TEXT NOT NULL UNIQUE, kind TEXT NOT NULL CHECK(kind IN ('customer','supplier')),
 created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS users (
 id BIGSERIAL PRIMARY KEY, username TEXT NOT NULL UNIQUE, password_hash TEXT NOT NULL,
 name TEXT NOT NULL, role TEXT NOT NULL CHECK(role IN ('admin','finance','coordinator','logistics','customer','supplier')),
 organization_id BIGINT REFERENCES organizations(id), active BOOLEAN NOT NULL DEFAULT true,
 created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS customer_memberships (
 user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 organization_id BIGINT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
 PRIMARY KEY(user_id, organization_id)
);
CREATE TABLE IF NOT EXISTS missions (
 id BIGSERIAL PRIMARY KEY, customer_org_id BIGINT NOT NULL REFERENCES organizations(id), created_by BIGINT NOT NULL REFERENCES users(id),
 model TEXT NOT NULL, service_type TEXT NOT NULL CHECK(service_type IN ('charge','repair','both')),
 warranty TEXT NOT NULL DEFAULT 'عادی', requested_qty INTEGER NOT NULL CHECK(requested_qty>0),
 collected_qty INTEGER CHECK(collected_qty>=0), delivered_qty INTEGER NOT NULL DEFAULT 0 CHECK(delivered_qty>=0),
 source_address TEXT NOT NULL, note TEXT NOT NULL DEFAULT '', status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','pickup','supplier','ready','financial','returning','completed','rejected','cancelled')),
 supplier_id BIGINT REFERENCES organizations(id), logistics_user_id BIGINT REFERENCES users(id),
 discrepancy_resolution TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
 CHECK (collected_qty IS NULL OR collected_qty<=requested_qty), CHECK (collected_qty IS NULL OR delivered_qty<=collected_qty)
);
CREATE TABLE IF NOT EXISTS batches (
 id BIGSERIAL PRIMARY KEY, mission_id BIGINT NOT NULL REFERENCES missions(id), qty INTEGER NOT NULL CHECK(qty>0),
 normal_qty INTEGER NOT NULL CHECK(normal_qty>=0), warranty_qty INTEGER NOT NULL CHECK(warranty_qty>=0),
 irreparable_qty INTEGER NOT NULL CHECK(irreparable_qty>=0), supplier_invoice_amount NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK(supplier_invoice_amount>=0),
 customer_invoice_amount NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK(customer_invoice_amount>=0),
 supplier_invoice_approved BOOLEAN NOT NULL DEFAULT false, customer_invoice_issued BOOLEAN NOT NULL DEFAULT false,
 paid_amount NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK(paid_amount>=0), status TEXT NOT NULL DEFAULT 'processing' CHECK(status IN ('processing','ready','cleared','in_transit','delivered')),
 created_at TIMESTAMPTZ NOT NULL DEFAULT now(), CHECK(normal_qty+warranty_qty+irreparable_qty=qty), CHECK(paid_amount<=customer_invoice_amount)
);
CREATE TABLE IF NOT EXISTS handovers (
 id BIGSERIAL PRIMARY KEY, mission_id BIGINT NOT NULL REFERENCES missions(id), batch_id BIGINT REFERENCES batches(id),
 kind TEXT NOT NULL CHECK(kind IN ('customer_pickup','supplier_delivery','supplier_pickup','customer_delivery')),
 qty INTEGER NOT NULL CHECK(qty>0), from_user_id BIGINT REFERENCES users(id), to_user_id BIGINT REFERENCES users(id),
 from_confirmed BOOLEAN NOT NULL DEFAULT false, to_confirmed BOOLEAN NOT NULL DEFAULT false,
 created_by BIGINT NOT NULL REFERENCES users(id), created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
 UNIQUE(mission_id,batch_id,kind)
);
CREATE TABLE IF NOT EXISTS events (
 id BIGSERIAL PRIMARY KEY, mission_id BIGINT NOT NULL REFERENCES missions(id), actor_id BIGINT NOT NULL REFERENCES users(id),
 label TEXT NOT NULL, details TEXT NOT NULL DEFAULT '', created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_mission_customer ON missions(customer_org_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mission_logistics ON missions(logistics_user_id, status);
CREATE INDEX IF NOT EXISTS idx_batches_mission ON batches(mission_id);
CREATE INDEX IF NOT EXISTS idx_events_mission ON events(mission_id, created_at DESC);
