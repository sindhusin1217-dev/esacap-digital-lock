# Escape the Digital Room

A self-contained classroom escape game. One file, no installation, no internet needed.

There are two ways to use it:

- **Standalone (one computer):** open `escape_digital_room.html` in a browser.
  Everything works, but results are saved in that browser only.
- **Classroom server (recommended):** double-click `start_server.bat` and let
  students connect from their own devices. The teacher's device shows every
  student's score. See [Classroom mode](#classroom-mode--scores-from-every-device).

Files: `escape_digital_room.html` (the game), `server.py` + `start_server.bat`
(classroom server), `share.html` (the class-code join page), `gate.html` (the join
code screen), and `start_public_link.bat` + `cloudflared.exe` (optional public
link). Keep these files in the same folder as the game.

## Play

Open `escape_digital_room.html` in Chrome, Edge, or Firefox.

- Round 1 (Easy) → unlock digit 1
- Round 2 (Medium) → unlock digit 2
- Round 3 (Hard) → unlock digit 3
- The three digits form the final password (default: **841**)

## How a round works

- A round can have **any number of questions** (1, 10, 25 — you decide).
- The student answers each question and presses **Confirm answer**.
- The game does **not** say whether an answer was right or wrong.
- After the **last question of the round**, it unlocks one digit and moves to the
  next round automatically after about 4 seconds (or immediately with **Next round**).
- **All answers in the round correct → the real digit** for that round.
- **Any wrong answer in the round → a decoy digit** (never one of the real password
  digits in the default setup), so the final code is wrong.
- After Round 3 the game checks the assembled code:
  - all three digits real → **YOU ESCAPED**
  - otherwise → **WRONG PASSWORD** screen showing the code they collected
- Incorrect choices are also counted silently for the teacher's scoreboard only.
- Every attempt **shuffles the questions and the answer options** separately on each
  device, so students do not see the same layout. Grading follows the answer text,
  so a perfect game still unlocks the real password.

## Mission result (end screen)

The end screen turns the number of correct answers into a mission rank:

| Correct answers | Mission result |
|---|---|
| 0–5 | You are still trapped! |
| 6–10 | You unlocked the second door! |
| 11–14 | Almost escaped! |
| 15 | Digital Room Escape Master! 🏆 |

Those bands are written for a 15-question game (5 per round). If the game has a
different number of questions, the same bands scale automatically, so a perfect
game always earns the Master rank.

## Timer

A live timer in the top bar counts from the moment the game starts.
When a round is finished, the time taken for that whole round is shown. The final
screen shows the total time and the time per round.

## Player name and scoreboard

- Before entering the room, each student types their name.
- Every game is recorded: name, escaped or ended, total time, time per round,
  wrong guesses, and date/time.
- The **Scoreboard** is inside the editor (after login) and is never shown to students.
  It shows how many players have taken part, how many escaped, the number of
  attempts, and the fastest escape, plus a full table of results.
- Teachers can export the results as a CSV file (opens in Excel) or clear the scoreboard.

## Classroom mode — scores from every device

Results live in each browser by default. To collect scores from student phones,
tablets or laptops on the same Wi-Fi, run the included tiny server (Python only,
no packages to install):

1. Double-click **`start_server.bat`** (or run `python server.py`).
   It opens the teacher page in your browser automatically.
2. The window prints the addresses, for example:
   - **This computer (teacher):** `http://localhost:8000`
   - **Students on the same Wi-Fi:** `http://192.168.1.23:8000`
   - **Join page:** `http://192.168.1.23:8000/share`
3. If the browser did not open, open the teacher address yourself.
4. On the projector, open the **Join page** address. It shows the **class code**
   (the address, for example `192.168.1.23:8000`), the **student join code**, and an
   **Enter the game** button.
5. On their own device, students open the class code address (or the public link),
   type the **join code**, then their name, and play.
6. Log into the editor as usual. The **Scoreboard** now lists attempts from every
   device and refreshes automatically every 5 seconds (there is also a Refresh button).

When the server is connected, the start screen also shows **Other devices:** with the
full link under **Enter the room**. Click it to open the game on this computer, or
press **copy** and send it to the class (for example in a chat or e-mail). It is only
shown on the teacher computer, not on student devices.

You can also simply give students the address `http://192.168.1.23:8000` directly.

If the join page says it is not connected, you opened the HTML file (or a preview)
instead of the server. Close it, run `start_server.bat`, and use the page that opens
at `http://localhost:8000`. (Restart the server after updating these files so it can
serve the join page.)

The **Editor login** button and the scoreboard are only shown when the page is
opened **on the computer running the server** (`http://localhost:8000`). On student
devices the button is hidden, so students cannot open the admin screen. If you need
the scoreboard on a different teacher device (for example a tablet), add
`?teacher=1` to the address: `http://192.168.1.23:8000/?teacher=1`. The editor
password is still required.

Notes:

- All devices must be on the same network. School Wi-Fi sometimes blocks
  device-to-device traffic; a phone hotspot works well as a fallback.
- If students cannot connect, allow Python through the Windows Firewall for
  **private** networks when Windows asks, or allow the printed port.
- Questions are stored on the teacher computer in `game_config.json`; results in
  `results.db`. Both files are created automatically and are **never** served to
  browsers (requesting them returns "not found").
- Editor changes say **"Saved on the server"** — that means every device will use
  them. Students who already have the page open should reload it.
- Clearing the scoreboard and editing questions affect all devices, because they
  are stored on the server.
- If the page is opened as a plain file or from a different web server without
  `server.py`, it automatically falls back to standalone mode (results stay on
  that device). The editor scoreboard shows which mode is active.
- Back up `game_config.json` and `results.db` if you want to keep the questions and
  scores. To start fresh, stop the server and delete those two files.

## Student join code (protects the link)

Every game link is protected by a short **join code**:

- The code is created automatically on the first server start. It is printed at
  startup in `server.log` (and in the server window if you start
  `start_server.bat` manually), for example `8NR2G5`.
- Students open the link and type the code **once**. The device remembers it for
  12 hours.
- The current code is shown in **Editor → Security → Student join code**, on the
  join page, and on the teacher start screen under **Other devices**.
- Change it in Editor → Security. Every device is then asked for the new code.
- Without the code nobody can open the game, read the questions from the server,
  or post fake scores. The editor password is a separate protection.
- Repeated wrong codes block the join page for one minute; the editor login is
  rate-limited too. The limit is high enough that a full class mistyping does
  not lock everyone out.

## Public link — students on any network (mobile data)

Students who are **not** on the same Wi-Fi, or whose network blocks
device-to-device traffic, use the **permanent public link**:

**https://zbivn325e6ul5m4kavgxotoqce.srv.us/**

- It is the same address **every day**, also after restarting Windows or the
  laptop.
- It needs **no account and no signup**.
- It starts automatically at login (the **Escape Digital Room (permanent link)**
  shortcut in the Windows Startup folder). `keep_public_link.ps1` +
  `watchdog_loop.ps1` check the server and the tunnel **every minute** and
  restart them if needed.
- The server runs hidden in the background. Its startup output is in
  `server.log`; any error is written to `server.err`.
- The current address is always shown on `http://localhost:8000/share` and saved
  in `public_link.txt`.
- Students type the **join code** once per device (12 hours). The editor and
  scoreboard are hidden from them, even if `?teacher=1` is added.

How it works: the laptop opens an SSH tunnel to the free, open-source
[srv.us](https://srv.us) service. The address is derived from the SSH key in this
folder, so reconnecting always returns the same address.

**Keep these files safe:** `serveo_key`, `serveo_key.pub`, `srvus_enabled.txt`
and `srvus_url.txt`. If `serveo_key` is deleted, the permanent address changes.
Copy them with the project when moving to another computer.

If srv.us is ever unavailable, the watchdog automatically falls back to a free
Cloudflare quick tunnel and updates `/share` and `public_link.txt` with the new
temporary address. A later restart returns to the permanent address.

### Optional: ngrok permanent link

If you prefer ngrok, double-click `Permanent student link (setup).bat`, sign up
free at <https://dashboard.ngrok.com/signup>, copy the **Authtoken** using the
dashboard's **Copy** button, and paste it into the setup window. Then delete or
rename `srvus_enabled.txt` so the watchdog uses ngrok instead. The free plan
includes one permanent `*.ngrok-free.app` address and shows a one-time
**“Visit Site”** button to new visitors (7-day cookie).

### Quick tunnel (temporary fallback)

`start_public_link.bat` still works for a quick test with Cloudflare. Its address
can change after a Windows restart.

Notes:

- The public link works only while this laptop is on and online.
- Anyone with the link can play, so only share it with your class.
- The teacher computer needs internet access.
- To stop the public link only: remove/rename `srvus_enabled.txt` and stop the
  `watchdog_loop.ps1` process, or stop the `ssh.exe` srv.us tunnel. The watchdog
  restarts it within a minute. `http://localhost:8000` keeps working.

## Focus lock (anti-cheating)

When a student clicks **Enter the room**:

- The game goes fullscreen (if the browser allows it).
- Switching tabs, opening another page, or losing window focus ends the attempt.
- Pressing `ESC` / leaving fullscreen ends the attempt.
- Closing or reloading the page shows a warning.

No website can fully block `Alt+Tab`; the game detects it and ends the attempt instead.
For stronger control, run the browser in kiosk mode on the student devices.

## Teacher / editor access

- Click **Editor login** at the bottom of the home screen (or press `Ctrl+Shift+E`).
- Default password: `admin123`
- **Change the password on first use** (Editor → Security).

The editor lets you change, for every round:

- the round name
- the secret digit
- the full list of questions: **+ Add question** for as many as you need,
  **Remove** to delete one
- for each question: the question text, all 4 answer options, and which one is correct

Every question in a round must be answered before that round's digit is revealed.
The digit is real only if **all** questions in the round were answered correctly.

You can also export/import questions as a JSON file and restore the demo questions.
Imported JSON uses this shape (old single-question files still import):

```json
{
  "rounds": [
    {
      "title": "Warm-up",
      "digit": "8",
      "questions": [
        { "question": "How many bits are in one byte?", "options": ["4","6","8","16"], "correct": 2 },
        { "question": "1 KB = ? bytes", "options": ["100","512","1024","2048"], "correct": 2 }
      ]
    }
  ]
}
```

## Important security note

The game runs grading in the student's browser, so the questions, correct answers
and secret digits are delivered to the page. A student who opens developer tools
could inspect them. The editor password prevents casual access only.

In classroom mode the questions are stored on the server in `game_config.json`
(only the password hash is stored there — never the password itself), but the
correct answers are still sent to the browser to grade the round.

The **join code** is checked on the server with an HttpOnly cookie, so the game
page, the questions and the result endpoint are not available to a visitor who has
not entered the code. Tunnel visitors (Cloudflare, ngrok, srv.us) are detected by
their forwarded IP or public Host header, so they are always treated as students;
the teacher screen is only available on this computer at `localhost`. A student
who is inside the game can still inspect the answers with developer tools (see
above).

The password itself is never displayed anywhere. Change the default password
before class.

## Reset

To wipe saved settings on one device, open the browser console and run:

```js
localStorage.removeItem('edr.config.v1')
```

Then reload the page.

In classroom mode the questions and results live on the server. To reset those,
stop the server and delete `game_config.json` and `results.db`; they are recreated
with the demo questions on the next start (the editor password returns to `admin123`).

