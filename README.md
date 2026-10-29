# CCS Robotics Attendance

Administrator attendance workspace for BEST Robotics and combined BattleBots / Rocketry seasons. Uses only `ccsrobotics/ccsroboticsatt`, GitHub Pages, and Supabase `oxphddigffxtmjuxnxad`. No Vercel resources.

## Run and deploy

Node 22+ is sufficient; there are no runtime npm dependencies. Run `npm test` and `npm run build`. Serve `dist` with a local static HTTP server. Production URL once Pages is enabled: https://ccsrobotics.github.io/ccsroboticsatt/ . Relative assets support the repository subpath.

An owner must select **Settings â†’ Pages â†’ Source â†’ GitHub Actions** if Pages is not enabled. The workflow tests, builds, and publishes every push to main. The connected GitHub app has push permission but no repository administration permission.

## Initial administrator

Supabase dashboard organization membership (including dstaggs15) is separate from application authentication. No Auth users existed at initial setup. In this project's Authentication â†’ Users, create your email/password user using the secure dashboard. Then execute in its SQL editor, substituting your email:

```sql
insert into public.administrators(user_id)
select id from auth.users where lower(email) = lower('YOUR_ADMIN_EMAIL')
on conflict do nothing;
```

Verify that one row was inserted. Sign in using that Auth user's credentials. Add later administrators using the same controlled process. Never put passwords or service-role keys in GitHub or chat. To revoke access, remove the administrator row and revoke the user's Auth sessions in the dashboard. The app checks administrator membership on every database operation through RLS. Public signups do not grant administrative access.

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

The browser contains only the project's public publishable key. All student records require a logged-in administrator; RLS also restricts audit access. Audit rows cannot be written by clients. Sessions remain in memory and refresh while the page stays open; reload requires signing in. Password reset and administrator provisioning use the secure Supabase dashboard. Student names, audit data, and exports are escaped. CSV formula prefixes are neutralized; Excel XML values are strings.

Schema migrations are under `supabase/migrations`. The initial migration was applied to the designated empty remote database. Do not reapply it manually to that project. Date ordering and roster/meeting season relationships are enforced by database constraints. Status updates are saved as one atomic upsert batch. Creating a student and enrolling it are separate requests; if enrollment fails, the student remains available in the existing-student picker.

Local checks cover business rules, export safety, JavaScript syntax, and build. Remote SQL checks cover RLS, correction auditing, and relational constraints. Interactive login and browser persistence need the first administrator account. Live deployment requires successful Pages workflow completion.
