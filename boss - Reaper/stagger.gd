extends State

var can_transition: bool = false

func enter():
	super.enter()                           
	can_transition = false                  
	animation_player.play("stagger")            
	await animation_player.animation_finished  
	can_transition = true              
	

func transition():
	if can_transition:
		get_parent().change_state("Follow")    
		can_transition = false
