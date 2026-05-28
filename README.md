# OpenWrt LuCI Theme: FoxHound (Beta)

A complete overhaul of the default OpenWrt LuCI Bootstrap theme – faster, cleaner, and ready for modern devices.  
This theme rebuilds the UI from the ground up while keeping the familiar Bootstrap core, then extends it with a professional dark dashboard, real‑time widgets, and a responsive mobile experience.

<img width="1920" height="1608" alt="foxhound" src="https://github.com/user-attachments/assets/8a009450-092c-4bd6-8566-7cdd86612f38" />


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
<img width="600" height="600" alt="fm" src="https://github.com/user-attachments/assets/d144bc17-c561-4637-ad1f-ea4747c30252" />
<br>
<br>

- New responsive breakpoints (`mobile.css`) ensure the interface works flawlessly on smartphones and tablets.  
- Touch‑friendly controls: larger buttons, reflowed tables (data‑title attributes), and a collapsible sidebar.  
- Tested on iOS, Android, and various screen sizes down to 320px.

### ✅ Easy Customisation  
- CSS custom properties (variables) are used throughout – change primary colours, border radius, shadows, or spacing in one place.  
- No need to edit every file: all theme variables are centralised in `palette.css`.

## How to Change the Theme Logo And Login Page Wallpaper 

### 🐦 Custom Logo

You can easily replace the logo with your own custom logo using one of two methods.

Method 1 : Edit the `header.ut` File

Locate and edit the `header.ut` file at:

/usr/share/ucode/luci/themplate/theme/foxhound

Inside this file, find the `<div>` with the class `left-head`. Look for the `<img>` tag and replace the `src` attribute with your own logo link:

```html
<img src="your-logo-link.png"></img>
````
Method 2 : Replace the SVG Logo File

If you prefer to keep the default filename, simply replace the existing SVG logo file at:

/www/luci-static/foxhound/resources/css/icons/svg/logo.svg

### 🖼️ Login Page Wallpaper 

<img width="800" height="437" alt="login" src="https://github.com/user-attachments/assets/89caeefe-e515-4a7d-b3ec-d63d6089dd88" />

To set a custom background image for the login page, use the `palette.css` file.

Locate the following variable at the top of the file:

```css
--login-wallpaper: url();
```


## 📦 Dependencies 

- Lua 
- libc
- libuci-lua
- lua-compat
- luci-lib-jsonc

### 🤝 Contributing

- Fork the repository and create a feature branch.
- Keep CSS changes inside the existing variable system.
- Test on a real OpenWrt device (or VM) before submitting a pull request.
- More device‑specific compatibility (e.g., MediaTek, Qualcomm).
- Update the documentation if you add new components.

> This project is designed and built solely for my own personal use, and it may not behave the same way on all routers. So, there might be bugs and issues with the text and box colors.
