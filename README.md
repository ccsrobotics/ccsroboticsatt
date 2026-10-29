# CARSS Dashboard site

Attendance workspace and parent portal for BEST Robotics and combined BattleBots / Rocketry seasons. Uses only `ccsrobotics/ccsroboticsatt`, GitHub Pages, and Supabase `oxphddigffxtmjuxnxad`. No Vercel resources.

## Run and deploy

Node 22+ is sufficient; there are no runtime npm dependencies. Run `npm test` and `npm run build`. Serve `dist` with a local static HTTP server. Production URL once Pages is enabled: https://ccsrobotics.github.io/ccsroboticsatt/ . Relative assets support the repository subpath.

An owner must select **Settings → Pages → Source → GitHub Actions** if Pages is not enabled. The workflow tests, builds, and publishes every push to main. The connected GitHub app has push permission but no repository administration permission.

## Initial administrator

Supabase dashboard organization membership (including dstaggs15) is separate from application authentication. No Auth users existed at initial setup. In this project's Authentication → Users, create your email/password user using the secure dashboard. Then execute in its SQL editor, substituting your email:

```sql
insert into public.administrators(user_id)
select id from auth.users where lower(email) = lower('YOUR_ADMIN_EMAIL')
on conflict do nothing;
```

The only approved administrator is `dstaggs@ccseagles.com`, as requested by the owner. Do not provision additional administrators. Never put passwords or service-role keys in GitHub or chat. The app checks administrator membership on every database operation through RLS. Parent signups do not grant administrative access.

## Parent access

Parents select **New parent? Create an account** on the sign-in page, confirm their email, and sign in. They submit their name, child's full name, relationship, and an optional note. There is no public student search or student-name directory.

The administrator sees a pending-request notification on the dashboard, refreshed every 30 seconds while the page is active, and a Requests tab. Verify the requester against school records or by direct contact, select the correct student, and approve or deny. Multiple children require separate requests. Approved parents see only their children's season enrollment, attendance percentages and meeting records, and warnings/suspensions. Parent accounts have no attendance editing, team exports, student management, audit access, or administrator privileges. Revocation removes database access immediately on the next request; parents can refresh their portal to update displayed data.

Access rules are enforced by PostgreSQL RLS, not just by the interface. Requests start pending; column grants and policies prevent self-approval, forging parent identity, changing student data, and viewing other parents' requests. Request email comes from the confirmed Auth user. Approval/revocation and all requests are audited. `test/parent-access.sql` verifies these rules inside a rolled-back transaction.

### Email setup required for public registration

Configure the project's Auth Site URL as `https://ccsrobotics.github.io/ccsroboticsatt/` and allow that redirect URL. Keep email confirmation enabled. Configure custom SMTP in Supabase Auth before inviting parents: Supabase's default SMTP only sends to project-team addresses and is not a production parent-mail sender. The connected MCP tools do not expose Auth/SMTP configuration. See https://supabase.com/docs/guides/auth/auth-smtp . Confirmation delivery and browser signup must be checked with a real parent address after this configuration; do not disable verification as a workaround.

## Appearance and encoding

The header button switches light/dark mode and stores the preference in this browser. The initial theme follows the operating system if no preference is saved. Parent pages use a narrower layout with distinct child cards. Source and deployment payloads must be read as UTF-8; GitHub uploads should serialize non-ASCII characters as JSON Unicode escapes to avoid Windows console encoding corruption. The sign-in arrow uses an HTML entity, and encoding regression checks cover public source files.

## Operations

1. Create a competition season, then add students or enroll existing students.
2. Create a meeting and mark each student Present, E, or UE. Unmarked rows stay unmarked; there is no implicit absence.
3. Save attendance. Correcting an existing status requires a reason; database triggers record old/new values and the acting administrator.
4. Open a student profile to review history and record formal warnings or suspensions.
5. Export the current season's entire roster or the selected student as CSV or Excel-compatible SpreadsheetML `.xml`. Open the XML file in Excel; this is not an `.xlsx` workbook.
6. Switch seasons for historical records. The audit tab loads the latest 200 changes across seasons. No client deletion controls are provided to preserve history.

## Attendance policy

Attendance = Present / (Present + UE). Excused and unmarked entries are excluded; this assumption is displayed in the dashboard. A student with no eligible marks has no percentage. Minimum is 70%; target is 75%. Future Present meetings needed solve `(P + n)/(P + UE + n) >= threshold`. Warnings and suspensions are manually recorded, not automatically imposed. If your school counts excused absences differently, adjust the documented policy and domain tests before use.

## Security and limitations

The browser contains only the project's public publishable key. Student records require a logged-in administrator or a parent approved for that specific student. Audit access remains administrator-only. Audit rows cannot be written by clients. Sessions remain in memory and refresh while the page stays open; reload requires signing in. Password resets use the secure Supabase dashboard. Student names, audit data, and exports are escaped. CSV formula prefixes are neutralized; Excel XML values are strings.

Schema migrations are under `supabase/migrations`. The initial migration was applied to the designated empty remote database. Do not reapply it manually to that project. Date ordering and roster/meeting season relationships are enforced by database constraints. Status updates are saved as one atomic upsert batch. Creating a student and enrolling it are separate requests; if enrollment fails, the student remains available in the existing-student picker.

Local checks cover business rules, export safety, JavaScript syntax, and build. Remote SQL checks cover RLS, correction auditing, and relational constraints. Interactive login and browser persistence need the first administrator account. Live deployment requires successful Pages workflow completion.
