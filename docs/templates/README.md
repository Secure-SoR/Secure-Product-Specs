# Templates for Secure SoR

## building-systems-register-template.csv

Use this as the expected format when implementing **Upload register** on the Physical and Technical page. The first row must be headers; column names are matched case-insensitively and with common variants (see implementation plan).

- **Required for insert:** System Name, systemCategory, Controlled By, Metering Status, Allocation Method.
- **Normalization:** Values are normalized to DB enums (e.g. Tenant → tenant, Submetered → partial). See [implementation-plan-lovable-supabase-agent.md](../implementation-plan-lovable-supabase-agent.md) § Upload building systems register.
