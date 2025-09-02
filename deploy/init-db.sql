-- Initialize QC System Database
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Grant additional permissions
GRANT CREATE ON SCHEMA public TO qc_user;
GRANT USAGE ON SCHEMA public TO qc_user;
