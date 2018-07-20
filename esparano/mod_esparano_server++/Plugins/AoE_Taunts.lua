function taunt(e)
    local ivalue = e.value:lower()

    for i,t in ipairs(TAUNTS) do
	    if ivalue == "/" .. i then
	        g2.net_send("","message",t)
	    end 
    end
end

add_listener("net_message", taunt, "AoE_Taunts")

TAUNTS = {
	"Yes.",
	"No.",
	"Food, please.",
	"Wood, please.",
	"Gold, please.",
	"Stone, please.",
	"Ahhhhhh!",
	"All hail King of the losers!",
	"Ooooohhhh.",
	"I'll beat you back to Age of Empires.",
	"HAHAHAHAHAHAHAHAHAHA.",
	"Ack! Bein' rushed!",
	"Sure blame it on your isp.",
	"Start the game already!",
	"Don't point that thing at me.",
	"Enemy sighted.",
	"It is good to be the king.",
	"Monk! I need a monk!",
	"Long time no seige.",
	"My granny can scrap better than that.",
	"Nice town. I'll take it.",
	"Quit touching me.",
	"Raiding party!",
	"Dadgum.",
	"Smite me!",
	"The wonder! The wonder! Nooooo!",
	"You played two hours to die like this?!",
	"You should see the other guy.",
	"Rogan?",
	"Wololo.",
	"Attack the enemy now.",
	"Cease creating extra villagers.",
	"Create extra villagers.",
	"Build a navy.",
	"Stop building a navy.",
	"Wait for my signal to attack.",
	"Build a wonder.",
	"Give me your extra resources.",
	"Ally.",
	"Enemy.",
	"Neutral.",
	"What age are you in?"
}