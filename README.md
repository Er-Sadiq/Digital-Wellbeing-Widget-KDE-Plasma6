# ⏳ Digital Wellbeing Widget

A minimal KDE Plasma 6 widget built with QML (and optional Java logic if extended) that helps you take care of your digital wellbeing.
It tracks your screen uptime and reminds you to take a short break every 20 minutes.

✨ Features

- Clean, rounded card design with responsive layout
- Displays screen uptime in real time
- Break reminders with smooth overlay notifications
- Configurable colors and break intervals
- Works seamlessly in both desktop and panel modes

## 🛠️ Technologies

- QML for UI and responsiveness
- JavaScript (logic.js) for time tracking and formatting
- KDE Plasma 6 APIs (PlasmoidItem, DataSource)

## 🚀 Installation

Copy the widget folder to ~/.local/share/plasma/plasmoids/

Rebuild Plasma shell:

kquitapp6 plasmashell && kstart6 plasmashell


Add the widget from Plasma’s Add Widgets menu.

### ⚙️ Configuration


  Change break interval (default: 20 minutes)
  Customize background and text color

## Demo

--
<img width="1920" height="1080" alt="Screenshot_20250907_205522" src="https://github.com/user-attachments/assets/c6fdb81e-363b-43bd-8196-fa92d67eab07" />
<img width="537" height="314" alt="Screenshot_20250914_133147" src="https://github.com/user-attachments/assets/19ba3f98-dd88-4be0-9f12-7ca4943ea32b" />


## 📜 License
MIT – free to use, modify, and share.
