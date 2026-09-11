# OpenWrt LuCI Theme : FoxHound

A complete overhaul of the default OpenWrt LuCI Bootstrap theme – faster, cleaner, and ready for modern devices.  
This theme rebuilds the UI from the ground up while keeping the familiar Bootstrap core, then extends it with a detailed dashboard, real‑time widgets, and a responsive mobile experience.

<img width="1920" height="1585" alt="foxhound" src="https://raw.githubusercontent.com/fullband7/openwrt-theme-foxhound/refs/heads/main/docs/showcase/dashboard.png" />

## 🎬 Live Demo

Experience the full FoxHound interface before installing.

**[Open Live Demo](https://fullband7.github.io/openwrt-theme-foxhound/demo)**  

## Features

### ✅ Live Widgets   
- Modern Grid Style 
- lightweight and Less Taxing on the Router  
- Fully Customizable

### ✅ Complete CSS Rewrite  
- **`cascade.css`** fully refactored: removed legacy code, fixed browser inconsistencies, and optimised animation performance.  
- All UI components (buttons, tables, dropdowns, progress bars) now use modern CSS (Grid, Flexbox, custom properties) without breaking LuCI’s original logic.

### ✅ PassWall2 Full Compatibility  
- The theme automatically detects and styles **PassWall2** pages
- Rewritten forms, tables, and action buttons – all maintain perfect alignment with the theme’s dark palette.  
- No more broken layouts or annoying overflows; every PassWall2 element is polished for both desktop and mobile.

### ✅ Easy Customisation  
- CSS custom properties (variables) are used throughout – change primary colours, border radius, shadows, or spacing in one place.  
- No need to edit every file: all theme variables are centralised in `palette.css`.

## Customization 

Effortlessly personalize your experience by applying custom logos & wallpapers and Customize the Dashboard Live Widgets (see more details in live demo)


<img width="600" height="600" alt="mobile" src="https://raw.githubusercontent.com/fullband7/openwrt-theme-foxhound/refs/heads/main/docs/showcase/settings.png" />

Want to take your personalization further? We’ve introduced a streamlined `palette.css` file, allowing you to perform deep design modifications with ease. Whether you’re looking to adjust specific brand colors, refine spacing, or restyle UI components.

### ✅ Mobile Optimised  
<br>
<img width="800" height="400" alt="mobile" src="https://raw.githubusercontent.com/fullband7/openwrt-theme-foxhound/refs/heads/main/docs/showcase/mockup.png" />
<br>
- New responsive breakpoints (`mobile.css`) ensure the interface works flawlessly on smartphones and tablets.  
- Touch‑friendly controls: larger buttons, reflowed tables (data‑title attributes), and a collapsible sidebar.  
- Tested on iOS, Android, and various screen sizes down to 320px.

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


### 🤝 Contributing

- Fork the repository and create a feature branch.
- Keep CSS changes inside the existing variable system.
- Test on a real OpenWrt device (or VM) before submitting a pull request.
- More device‑specific compatibility (e.g., MediaTek, Qualcomm).
- Update the documentation if you add new components.

> This project is designed and built solely for my own personal use, and it may not behave the same way on all routers. So, there might be bugs and issues with the text and box colors.

