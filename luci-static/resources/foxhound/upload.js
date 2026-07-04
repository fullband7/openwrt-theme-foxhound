function hardReload() {
    setTimeout(function() {
        window.location.replace(window.location.pathname + '?t=' + new Date().getTime());
    }, 1500);
}

function handleUpload(e, t) {
    var n = document.getElementById(e), o = n.files[0];
    document.getElementById("msg-success").style.display = "none";
    document.getElementById("msg-format").style.display = "none";
    document.getElementById("msg-error").style.display = "none";
    if (o) {
        if (o.size > 2097152) return document.getElementById("msg-format").querySelector("p").textContent = "Error: File too large. Maximum size is 2MB.", void (document.getElementById("msg-format").style.display = "block");
        var a = o.name.split(".").pop().toLowerCase();
        if (-1 !== ["png", "jpg", "jpeg", "svg", "gif", "webp"].indexOf(a)) {
            var r = new FileReader;
            r.onload = function (e) {
                var o = e.target.result.split(",")[1];
                fetch(t, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ ext: a, file_data: o }) }).then((function (e) {
                    if (e.ok) {
                        document.getElementById("msg-success").style.display = "block";
                        n.value = "";
                        hardReload();
                    } else {
                        document.getElementById("msg-error").style.display = "block";
                    }
                })).catch((function () { document.getElementById("msg-error").style.display = "block" }))
            }, r.readAsDataURL(o)
        } else document.getElementById("msg-format").style.display = "block"
    }
}

function handleBgUpload(e, t) {
    var n = document.getElementById(e), o = n.files[0];
    document.getElementById("msg-success").style.display = "none";
    document.getElementById("msg-format").style.display = "none";
    document.getElementById("msg-error").style.display = "none";
    if (o) {
        if (o.size > 2097152) return document.getElementById("msg-format").querySelector("p").textContent = "Error: File too large. Maximum size is 2 MB.", void (document.getElementById("msg-format").style.display = "block");
        var a = o.name.split(".").pop().toLowerCase();
        if ("jpg" === a || "jpeg" === a) {
            var r = new FileReader;
            r.onload = function (e) {
                var o = e.target.result.split(",")[1];
                fetch(t, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ file_data: o }) }).then((function (e) {
                    if (e.ok) {
                        document.getElementById("msg-success").style.display = "block";
                        n.value = "";
                        hardReload();
                    } else {
                        document.getElementById("msg-error").style.display = "block";
                    }
                })).catch((function () { document.getElementById("msg-error").style.display = "block" }))
            }, r.readAsDataURL(o)
        } else document.getElementById("msg-format").querySelector("p").textContent = "Error: Only JPG/JPEG files are allowed for backgrounds.", document.getElementById("msg-format").style.display = "block"
    }
}

function handleReset(e) {
    document.getElementById("msg-success").style.display = "none";
    document.getElementById("msg-format").style.display = "none";
    document.getElementById("msg-error").style.display = "none";
    fetch(e, { method: "POST" }).then((function (e) {
        if (e.ok) {
            document.getElementById("msg-success").style.display = "block";
            hardReload();
        } else {
            document.getElementById("msg-error").style.display = "block";
        }
    })).catch((function () { document.getElementById("msg-error").style.display = "block" }))
}

document.getElementById("upload_main_btn").addEventListener("click", (function () { window.confirm("Are you sure you want to apply this change?") && handleUpload("logo_file", '<%=luci.dispatcher.build_url("admin", "system", "foxhound", "upload_main")%>?token=<%=token%>') }));
document.getElementById("upload_login_btn").addEventListener("click", (function () { window.confirm("Are you sure you want to apply this change?") && handleUpload("login_file", '<%=luci.dispatcher.build_url("admin", "system", "foxhound", "upload_login")%>?token=<%=token%>') }));
document.getElementById("reset_main_btn").addEventListener("click", (function () { window.confirm("Are you sure you want to reset to default?") && handleReset('<%=luci.dispatcher.build_url("admin", "system", "foxhound", "reset_main")%>?token=<%=token%>') }));
document.getElementById("reset_login_btn").addEventListener("click", (function () { window.confirm("Are you sure you want to reset to default?") && handleReset('<%=luci.dispatcher.build_url("admin", "system", "foxhound", "reset_login")%>?token=<%=token%>') }));
document.getElementById("upload_bg_main_btn").addEventListener("click", (function () { window.confirm("Are you sure you want to apply this change?") && handleBgUpload("bg_main_file", '<%=luci.dispatcher.build_url("admin", "system", "foxhound", "upload_bg_main")%>?token=<%=token%>') }));
document.getElementById("upload_bg_login_btn").addEventListener("click", (function () { window.confirm("Are you sure you want to apply this change?") && handleBgUpload("bg_login_file", '<%=luci.dispatcher.build_url("admin", "system", "foxhound", "upload_bg_login")%>?token=<%=token%>') }));
document.getElementById("reset_bg_main_btn").addEventListener("click", (function () { window.confirm("Are you sure you want to reset the background?") && handleReset('<%=luci.dispatcher.build_url("admin", "system", "foxhound", "reset_bg_main")%>?token=<%=token%>') }));
document.getElementById("reset_bg_login_btn").addEventListener("click", (function () { window.confirm("Are you sure you want to reset the background?") && handleReset('<%=luci.dispatcher.build_url("admin", "system", "foxhound", "reset_bg_login")%>?token=<%=token%>') }));

document.getElementById("save_about_btn").addEventListener("click", function () {
    var text = document.getElementById("about_text_input").value;
    if (window.confirm("Are you sure you want to save this text?")) {
        fetch('<%=luci.dispatcher.build_url("admin", "system", "foxhound", "save_about")%>?token=<%=token%>', {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ text: text })
        }).then(function(e) {
            if (e.ok) {
                alert("Saved successfully!");
                window.location.reload();
            } else {
                alert("Error saving. Please check the text length.");
            }
        }).catch(function() {
            alert("Connection error.");
        });
    }
});