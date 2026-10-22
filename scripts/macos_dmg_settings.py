# dmgbuild 配置：天工阁 macOS 拖拽安装窗口。
#
# 由 scripts/build_macos_dmg.sh 调用：
#   dmgbuild -s scripts/macos_dmg_settings.py \
#     -D app_path=<绝对路径>/天工阁.app \
#     -D app_name=天工阁.app \
#     -D background=<绝对路径>/background.png \
#     "天工阁 v<版本>" <输出>.dmg
#
# 坐标是相对窗口内容区（不含标题栏）的图标中心点，单位为 pt。

app_path = defines.get('app_path')
app_name = defines.get('app_name', '天工阁.app')
background_path = defines.get('background')

files = [(app_path, app_name)]
symlinks = {'Applications': '/Applications'}

# 两个图标中心：与背景图里的箭头两端对齐（背景宽 780）。
icon_locations = {
    app_name: (209, 249),
    'Applications': (649, 249),
}

background = background_path
window_rect = ((140, 120), (780, 546))
default_view = 'icon-view'

# 底部的「N 个项目，可用 X GB」交给 Finder 真实状态栏，而不是画进背景。
show_status_bar = True
show_tab_view = False
show_toolbar = False
show_sidebar = False
show_pathbar = False
show_icon_preview = False

icon_size = 118
text_size = 13

format = 'UDZO'
compression_level = 9
