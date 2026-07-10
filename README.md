# OpenWrt LuCI Theme : FoxHound

A complete overhaul of the default OpenWrt LuCI Bootstrap theme – faster, cleaner, and ready for modern devices.  
This theme rebuilds the UI from the ground up while keeping the familiar Bootstrap core, then extends it with a professional dashboard, real‑time widgets, and a responsive mobile experience.

<img width="1920" height="1585" alt="foxhound" src="https://raw.githubusercontent.com/fullband7/openwrt-theme-foxhound/refs/heads/main/assets/dashboard.png" />

## 🚀 Features

### ✅ Complete CSS Rewrite  
- **`cascade.css`** fully refactored: removed legacy code, fixed browser inconsistencies, and optimised animation performance.  
- All UI components (buttons, tables, dropdowns, progress bars) now use modern CSS (Grid, Flexbox, custom properties) without breaking LuCI’s original logic.

### ✅ PassWall2 Full Compatibility  
- The theme automatically detects and styles **PassWall2** pages
- Rewritten forms, tables, and action buttons – all maintain perfect alignment with the theme’s dark palette.  
- No more broken layouts or annoying overflows; every PassWall2 element is polished for both desktop and mobile.

### ✅ Mobile Optimised  
<br>
<img width="600" height="600" alt="mobile" src="https://raw.githubusercontent.com/fullband7/openwrt-theme-foxhound/refs/heads/main/assets/mobile.jpg" />
<br>
<br>

- New responsive breakpoints (`mobile.css`) ensure the interface works flawlessly on smartphones and tablets.  
- Touch‑friendly controls: larger buttons, reflowed tables (data‑title attributes), and a collapsible sidebar.  
- Tested on iOS, Android, and various screen sizes down to 320px.

### ✅ Easy Customisation  
- CSS custom properties (variables) are used throughout – change primary colours, border radius, shadows, or spacing in one place.  
- No need to edit every file: all theme variables are centralised in `palette.css`.

## ⬇️ Installation 

OpenWrt 24.10

```bash
wget -O /tmp/luci-theme-foxhound.ipk https://github.com/fullband7/openwrt-theme-foxhound/releases/latest/download/luci-theme-foxhound.ipk
opkg install /tmp/luci-theme-foxhound.ipk
rm /tmp/luci-theme-foxhound.ipk
service rpcd restart
```

OpenWrt 25.12

```bash
wget -O /tmp/luci-theme-foxhound.apk https://github.com/fullband7/openwrt-theme-foxhound/releases/latest/download/luci-theme-foxhound.apk
apk add --allow-untrusted /tmp/luci-theme-foxhound.apk
rm /tmp/luci-theme-foxhound.apk
service rpcd restart
```
### <mark> > Reboot is required</mark>

## 🐦 Custom Logo And Wallpaper 

Effortlessly personalize your experience by applying custom logos and wallpapers to both the dashboard and login screens.


<img width="700" height="600" alt="mobile" src="https://raw.githubusercontent.com/fullband7/openwrt-theme-foxhound/refs/heads/main/assets/settings.png" />

Want to take your personalization further? We’ve introduced a streamlined `palette.css` file, allowing you to perform deep design modifications with ease. Whether you’re looking to adjust specific brand colors, refine spacing, or restyle UI components.

## 📦 Dependencies 

- lua 
- libc
- libuci-lua
- luci-compat
- luci-lib-jsonc
- luci-lua-runtime

### 🤝 Contributing

- Fork the repository and create a feature branch.
- Keep CSS changes inside the existing variable system.
- Test on a real OpenWrt device (or VM) before submitting a pull request.
- More device‑specific compatibility (e.g., MediaTek, Qualcomm).
- Update the documentation if you add new components.

> This project is designed and built solely for my own personal use, and it may not behave the same way on all routers. So, there might be bugs and issues with the text and box colors.

