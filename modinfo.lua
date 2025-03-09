name="Infernal Forge"
version="3.5.24"
description="Welcome To Infernal Forge!    Version 3.5.24"
author="crazyfreddy & sock"
--forumthread=""
api_version=10
priority=2048
dont_starve_compatible=false
reign_of_giants_compatible=false
dst_compatible=true
forge_compatible=true

folder_name = folder_name or "workshop-"
if not folder_name:find("workshop-") then
    name = name.." - Test Ver."
end

all_clients_require_mod=true
client_only_mod=false
icon_atlas = "images/modicon.xml"
icon = "modicon.tex"
server_filter_tags={"infernal forge"}