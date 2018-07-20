function taunt(e)
    local ivalue = e.value:lower()

    if ivalue:find("esperano") ~= nil then
        g2.net_send("","message","It's spelled espArano. Thank you.")
    end
end

add_listener("net_message", taunt, "AoE_Taunts")