# NeoBuddy

An iOS (SwiftUI) NICU reference app: neonatal resuscitation drills, emergency
condition algorithms with role/equipment checklists, weight-based drug
calculations, arrhythmia algorithms, and infusion planning.

## Building

1. Open `kkhs2.xcodeproj` in Xcode 16 or newer.
2. The project uses synchronized folders — sources in `kkhs2/` build automatically.
3. Add two local (git-ignored) files, which are intentionally **not** in the repo:

   | File | Purpose |
   |---|---|
   | `kkhs2/GoogleService-Info.plist` | Firebase Auth config — download from your Firebase console. |
   | `kkhs2/AI Feature Config.xcconfig` | AI copilot key — create with `GEMINI_API_KEY = <your key>` and assign it to the target's build configurations. |

4. Cloud-synced custom conditions use Supabase. Run `supabase_setup.sql` once in
   your Supabase dashboard (SQL Editor) to create the table and RLS policies.

## Security notes

- Secret configuration files are git-ignored; never commit real keys.
- The Supabase publishable key embedded in `ConditionSyncService.swift` is a
  public, RLS-governed key by design.
