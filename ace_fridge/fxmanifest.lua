fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ace_fridge'
description 'World fridges: consumable storage with a rail-style menu. Qbox / QB-Core / ESX.'
author 'itsmiggy'
version '1.0.0'

ui_page 'web/index.html'

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

files {
    'web/index.html',
    'web/app.js',
    'web/style.css',
}
