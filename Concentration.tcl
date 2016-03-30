# Concentration.tcl
# Feb 03 2016
# Editor: Josh

package require Tk

################################################################
# proc loadImages {}-- 
#    Load the card images
# Arguments
#   NONE
#
# Results
#   The global array "concentration" is modified to include a
#   list of card image names
#

proc loadImages {} {

	global concentration

  # The card image fileNames are named as S_V.gif where
  #  S is a single letter for suit (Hearts, Diamonds, Spades, Clubs)
  #  V is a 1 or 2 character descriptor of the suit - one of:
  #     a k q j 10 9 8 7 6 5 4 3 2
  #
  # glob returns a list of fileNames that match the pattern - *_*.gif
  #  means all fileNames that have a underbar in the name, and a .gif extension.
  
  foreach fileName [glob *_*.gif] {
	# We discard the aces to leave 48 cards because that makes 6*8 display.
	if { 
	($fileName ne "c_a.gif") &&
	($fileName ne "h_a.gif") &&
	($fileName ne "d_a.gif") &&
	($fileName ne "s_a.gif") 
	} {
		# split the card name e.g., c_8 from the suffix .gif
		
		set card [lindex [split $fileName .] 0]
		
		# Create an image with the card name, using the file and save a list of the card images: concentration(cards)
		
		image create photo $card -file $fileName
		lappend concentration(cards) $card
	}
	
	# Load the images to use for the card back and for blank cards	
	
  foreach fileName {blank.gif back.gif} {
		# split the card name from the suffix (.gif)
		
		set card [lindex [split $fileName .] 0]
		
		# Create the image
		image create photo $card -file $fileName
		
	}
	
  }

}

################################################################
# proc randomizeList {}--
#    Change the order of the cards in the list
# Arguments
#   originalList        The list to be shuffled
#   
# Results
#   The concentration(cards) list is changed - no cards will be lost
#   of added, but the order will be random.
#   

proc randomizeList {originalList} {

	# How many cards are we playing with.
	set listLength [llength $originalList]
	
	# Initialize a new (random) list to be empty
	set newList {}
	
	# Loop for as many cards as are in the card list at the start. Then we remove one card on each iteration of the loop.
	
	for {set i $listLength} {$i > 0} {incr i -1} {
		
		# Selethe ct a random card from the remaining cards.
		set p1 [expr int(rand() * $i)]
		
		# Put that card onto the new list of cards
		lappend newList [lindex $originalList $p1]
		
		# Remove that card from the card list.
		set originalList [lreplace $originalList $p1 $p1]
		
	}
	
	# the old list is empty and the new list has all the elements or cards
	
	return $newList
}

#Ok, that loads the card images and shuffles the deck. We're on the home stretch now. 

#In order to make a replayable game, we need to have 4 procedures that work together: 


#• makeGameBoard. This procedure is called once, when the game starts to create the all widgets 
#• startGame. This procedure is called each time we start a game. It initializes the global variables and configures the buttons. 
#• playerTurn. This is called each time the player takes a turn. In this case, each time the player clicks a button. 
#• endGame. This is called once at the end to clean up any loose ends, report the final score, and ask the player if they want to play again. It will call startGame if the player wants to keep playing. 

#I added one more procedure to this list for this game - checkForFinished. This procedure gets called from playerTurn to see if the player has found the last card yet. The code that does the check is very small (a single if statement), but by putting this into a separate procedure it will be easier to change the rules for winning the game if we want to. 

################################################################
# proc makeGameBoard {}--
#    Create the game board widgets - canvas and labels.
# Arguments
#   NONE 
#   
# Results
#   New GUI widgets are created.


proc makeGameBoard {} {
	# Create and grid the canvas that will hold the card images
	canvas .game -width 900 -height 726 -bg gray
	grid .game -row 1 -column 1 -columnspan 6
	
	# Create and grid the labels for tuurns and score
	
	label .lmyScoreLabel -text "My Score"
	label .lmyScore -textvariable concentration(player,score)
	label .lcompScoreLabel -text "Computer Score"
	label .lcompScore -textvariable concentration(computer,score)
	label .lturnLabel -text "Turn"
	label .lturn -textvariable concentration(turn)
	
	grid .lmyScoreLabel -row 0 -column 1 -sticky e
	grid .lmyScore -row 0 -column 2 -sticky w
	grid .lcompScoreLabel -row 0 -column 3 -sticky e
	grid .lcompScore -row 0 -column 4 -sticky w
	grid .lturnLabel -row 0 -column 5 -sticky e
	grid .lturn -row 0 -column 6 -sticky w
	
#	set numberOfCards [llength $cardList]
	
#	for {set i 0} {$i < $numberOfCards} {incr i} {
		# 8 cards each row
#		set row [expr ($i / 8) + 1]
#		set column [expr $i % 8]
		
		# Create and grid the button (command and image will be cofigured by after procedure)
		
#		button .b_$i
#		grid .b_$i -row $row -column $column
#	}
}
################################################################
# proc startGame {}--
#    Actually start a game running
# Arguments
#   NONE
# 
# Results
#   initializes per-game indices in the global array "concentration"
#   The card list is randomized
#   The GUI is modified.
# 

proc startGame {} {
	global concentration
	set concentration(player,score) 0
	set concentration(computer,score) 0
	set concentration(turn) 0
	set concentration(selected,rank) {}
	set concentration(known) {}
	
	set concentration(computer,x) 0
	set concentration(computer,y) 0
	
	set concentration(player,x) 810
	set concentration(player,y) 0
	
	set concentration(cards) [randomizeList $concentration(cards)]
	
	# set numberOfCards [llength $concentration(cards)]
	
	# Get the height and width of the cards
	set height [image height [lindex $concentration(cards) 0]]
	set width [image width [lindex $concentration(cards) 0]]
	
	# Leave spaces between cards.
	incr width 2
	incr height 2
	
	# Remove any existing items on the canvas .game delete all
	.game delete all
	
	# Start in the upper left corner
	# set x 2
	set x 90
	set y 0
	
	# Step through the list of cards
	
	for {set pos 0} {$pos < [llength $concentration(cards)]} {incr pos} {
		# Place the back-of-a-card image on the board to simulate a card that is face-down.
		.game create image $x $y -image back -anchor nw -tag card_$pos
		
		# Add a binding procedure to a left-clicking on a certain average.
		.game bind card_$pos <ButtonRelease-1> "playerTurn $pos"
		
		# Step to the next column (the width of a card) 
		incr x $width
		
		# If we have put 8 columns of cards, reset X to the far left, and step down one row.
		
		if {$x >= [expr 90 + ($width * 8)]} {
			set x 90
			incr y $height
		}
	}
}

#flipImageX.tcl
################################################################
# proc flipImageX {canvas canvasID start end background}--
#    Makes it appear that an image object on a canvas is being flipped
# Arguments
#   canvas	The canvas holding the image
#   canvasID	The identifier for this canvas item
#   start	The initial image being displayed
#   end		The final  image to display
#   background  The color to show behind the image being flipped.
#               This is probably the canvas background color
# 
# Results
#   configuration for the canvas item is modified.
# 

proc flipImageX {canvas canvasID start end background} {
	global concentration
	
	# Get the height/width of the image we will be using
	set width [image width $start]
	set height [image height $start]
	
	# The iamge will rotate arount the X axis
	# Calculate and save the center, since we wil be uisng it a lot
	
	set centerX [expr $width / 2]
	
	# Create a new temp image that we'll be modifying
	image create photo temp -height $height -width $width
	
	# Copy a new temp image that we'll be modifying Canvas to show our temp image, instead of the original image
	
	temp copy $start
	
	$canvas itemconfigure $canvasID -image temp
	
	update idle
	after 25
	
	# Copy the start image into the temp with incrementing subsampling.
	
	# Make the copy to area towards the center from left
	
	for {set i 2} {$i < 8} {incr i} {
		set left [expr $centerX - $width / (2 * $i)]
		set right [expr $centerX + $width / (2 * $i)]
		temp put $background -to 0 0 $width $height
		temp copy -to $left 0 $right $height -subsample $i 1 $start
		update idle
		after 25
	}

	# Copy the end image the temp with decrementing subsampling 
	
	# Make the copy area towards the left from center
	
	for {set i 8} {$i > 1} {incr i -1} {
		set left [expr $centerX - $width / (2 * $i)]
		set right [expr $centerX + $width / (2 * $i)]
		temp put $background -to 0 0 $width $height
		temp copy -to $left 0 $right $height -subsample $i 1 $end 
		update idle
		after 25
	}
	
	# configure the canvas to show the final image, and delete our temporary image
	# delete our temporary image $canvas itemconfigure $canvasID -image $end image delete temp
	
	$canvas itemconfigure $canvasID -image $end
	image delete temp
	
}

################################################################
# proc moveCards {cvs id1 id2 prefix}--
#    moves Cards from their current location to the 
#  score pile for
# Arguments
#   id1         An identifier for a canvas item
#   id2         An identifier for a canvas item
#   prefix      Identifier for which location should get the card
#
# Results
#
#
proc moveCards {id1 id2 prefix} {
	global concentration
	
	set step 100
	
	.game raise $id1
	.game raise $id2
	
	#get the X  and  Y coordinates for the two cards
	
	foreach {c1x c1y} [.game coords $id1] {break}
	foreach {c2x c2y} [.game coords $id2] {break}
	
	# Calculate thhe distance that this card is from where it needs to go.
	
	set d1x [expr $concentration($prefix,x) - $c1x]
	set d1y [expr $concentration($prefix,y) - $c1y]
	
	set d2x [expr $concentration($prefix,x) - $c2x]
	set d2y [expr $concentration($prefix,y) - $c2y]
	
	# steps
	
	set step1x [expr $d1x / $step]
	set step1y [expr $d1y / $step]
	
	set step2x [expr $d2x / $step]
	set step2y [expr $d2y / $step]
	
	# Loop 10 times, moving the card 1/10 'th the distance to the new location.Pasue 1/10 second (100 ms) each step.
	
	for {set i 0} {$i < $step} {incr i} {
		.game move $id1 $step1x $step1y
		.game move $id2 $step2x $step2y
		update idle
		after [expr int(1000 / $step)]
	}
	
#	.game coords $id1 $concentration($prefix,x) $concentration($prefix,y)
	
#	.game coords $id2 $concentration($prefix,x) $concentration($prefix,y)
	
	incr concentration($prefix,y) 30
	

}

#########################################################
# Add known card
#
# Argument: 
#	card : the content of the card like d_4
#	pos  : the position of this card like 5
#
proc addKnownCard  {card pos} {
  global concentration
  puts "add Known $card $pos"
  set p [lsearch $concentration(known) $card]
  if {$p < 0} {
    lappend concentration(known) $card $pos
  }
}


################################################################
# proc removeKnownCard {}--
#    Remove a pair of known cards from the known card list
# Arguments
#   carID	a card value like d_4
# 
# Results
#   State index known is modified if the cards were known
# 
proc removeKnownCard {cardID} {
	global concentration
		set p [lsearch $concentration(known) $cardID]
		if {$p >= 0} {
			
			# removing both the card content (cardID) and its position in the list
			
			set concentration(known) \
			[lreplace $concentration(known) $p [expr $p +1]]
		}
}


################################################################
# proc playerTurn {position }--
#    Selects a card for comparison, or checks the current
#    card against a previous selection.
# Arguments
#   position    The position of this card in the list of card images
#
# Results
#     The selection fields of the global array "concentration"
#     are modified.
#     The GUI is modified.
# 

proc playerTurn {position} {
	global concentration
	
	set card [lindex $concentration(cards) $position]
	#.game itemconfigure card_$position -image $card
	
	# instead of use itemconfigure to show the card image
	# We now use flipImagex to "flip" the image
	flipImageX .game card_$position back $card gray
	
	
	# As if computer remembers the cards I filp
	addKnownCard $card $position
	
	# rank is the "number" on the card
	set rank [lindex [split $card _] 1]
	
	# Lower the card button to show the image of this card instead of the original card back
	
	# This makes it look like we turned a card from being face down to face up.
	
	#.b_$position configure -image $card
	
	
	
	if {{} eq $concentration(selected,rank)} {
		
		# If concentration(selected,rank) is empty, this is the first part of a turn. Mark this card as selected and we are done.
		
		# increment the turn counter
		incr concentration(turn)
		
		# store the selected card's rank
		set concentration(selected,rank) $rank
		
		# store the selected card's image 
		set concentration(selected,card) $card
		
		# store the selected card's button 
		set concentration(selected,position) $position
		
	} else {
		
		# If concentration(selected,rank) is not empty, then this is the second part of this turn.
		
		# Comparee the rank of this card to the previous saved rank.
		
		# Update the screen *Now* (to show the card), and pause for one second
		
		update idle
		# update
		after 1000
		
		if {$position == $concentration(selected,position)} {
			return
		}
		
		if {$rank eq $concentration(selected,rank)} {
		
		removeKnownCard $card
		removeKnownCard $concentration(selected,card)
		
		set foundMatch TRUE
		
		# If the ranks are identical, increase the score by one
		
		incr concentration(player,score)
		
		# Remove the two cards and their backs from the board
		#.b_$position configure -image blank -command {}
		#.b_$concentration(selected,buttonNum) configure -image blank -command {}
		
			# Remove the two cards and their backs from the board
			#.game itemconfigure card_$position -image blank
			#.game itemconfigure card_$concentration(selected,position) -image blank
			.game bind card_$position <ButtonRelease-1> ""
			.game bind card_$concentration(selected,position) <ButtonRelease-1> ""
			
			moveCards card_$position \
			card_$concentration(selected,position) player
		
			# Check if its the end of the game
			if {[checkForFinished]} {
			endGame
			}
		} else {
		
		set foundMatch FALSE
		
			# if the rank of the two cards are not the same, show the back of the two cards.
			#.game itemconfigure card_$position -image back
			#.game itemconfigure card_$concentration(selected,position) -image back
			
			flipImageX .game card_$concentration(selected,position) \
			$concentration(selected,card) back gray	
			
			flipImageX .game card_$position $card back gray	
		}
				
		# This is normally the last procedure in this branch. That is, either the two cards are a match or not, clear the previous selected rank
		
		set concentration(selected,rank) {}
		
		if {$foundMatch eq "FALSE"} {		
			# If the player failed to find a match, the computer gets a turn
			
			computerTurn	
		}		
	}
}

################################################################
# proc chooseRandomPair {}--
#    Choose two random face-down cards from the board
# Arguments
#   NONE
# 
# Results
#   No Side Effects
# 
proc chooseRandomPair {} {
	global concentration
	
	# Each "card" is originally an area of the canvas .game.
	# At the beginning of the game we assigned a tag to that area. That makes the tag associated with a speicifc "card".
	# As what the "card" really is hold in a list
	# So we iterate through all the tags (card_NUMBER), check if the area is showing the back image, if yes, we identify the tag (card_NUMBER) and put the NUMBER in the list: cards.
	# NUMBER is also the position or pos of the of this card's content as an element in another list.
	
	foreach item [.game find all] {
		if {[.game itemcget $item -image] eq "back"} {
			set tag [lindex [.game itemcget $item -tag] 0]
			lappend cards [lindex [split $tag _] 1]
		}
	}
	
	# The length of this list (cards), or the amount of the aligible positions have been collected, indicates how many "cards" are still available in the game now
	
	set availableCount [llength $cards]
	
	set guess1 [expr int(rand() * $availableCount)]
	
	for {set guess2 $guess1} {$guess2 == $guess1} \
	{set guess2 [expr int(rand() * $availableCount)]} {
	}
	
	puts "RTN: $guess1 $guess2 -> [list [lindex $cards $guess1] [lindex $cards $guess2]]"
	
	return [list [lindex $cards $guess1] [lindex $cards $guess2]]
	
}

################################################################
# proc findKnownPair {}--
#    Return a pair of cards that will match, 
#    Return an empty list if no known match available.
#
# Arguments
#   NONE
# 
# Results
#   No Side Effect
# 

proc findKnownPair {} {
	global concentration
	
	set currentPosition 1 
	
	foreach {card1 pos1} $concentration(known) {
		foreach {suit rank} [split $card1 _] {break;}
		
		# Look for a card with the same rank in the list
		set p [lsearch -start $currentPosition $concentration(known) "*_$rank"]
		
		if {$p >= 0} {
			set card2 [lindex $concentration(known) $p]
			set pos2 [lindex $concentration(known) [expr $p + 1]]
			
			return [list $pos1 $pos2]
		}
		incr currentPosition 2
	}
	return {}
}

################################################################
# proc computerTurn {}--
#    The computer takes a turn
# Arguments
#   NONE
# 
# Results
#   GUI can be modified.
#   concentration(computer,score) may be modified.  Game may end.
# 

proc computerTurn {} {
	global concentration
	
	set pair [findKnownPair]
	puts "oo $pair"
	
	if {[llength $pair] != 2} {
		set pair [chooseRandomPair]
	}
	puts "xx $pair"
	
	
	# This is the position of these card

	set pos1 [lindex $pair 0]
	set pos2 [lindex $pair 1]
	
	puts "ox $pos1 $pos2"
	
	# Get the "images" (content, e.g., d_4) from by its position
	
	set image1 [lindex $concentration(cards) $pos1]
	set image2 [lindex $concentration(cards) $pos2]
	
	addKnownCard $image1 $pos1
	addKnownCard $image2 $pos2
	
	# Split the card image name into the suit and rank. Save the rank.
	set rank1 [lindex [split $image1 _] 1]
	set rank2 [lindex [split $image2 _] 1]
		
		# Flip the cards to show the front side.
		flipImageX .game card_$pos1 back $image1 gray
		flipImageX .game card_$pos2 back $image2 gray
		
		# Update the screen and wait a couple seconds for the human player to see what is showing
		
		update idle
		after 1000
		
		if {$rank1 eq $rank2} {
			# If we are here, then the ranks are the same
			
			removeKnownCard $image1
			removeKnownCard $image2
			
			incr concentration(computer,score) 1
			
			moveCards card_$pos1 card_$pos2 computer
			
			if {[checkForFinished]} {
				endGame
				return
			}
			
			computerTurn
			
		} else {
			
			flipImageX .game card_$pos1 $image1 back gray
			flipImageX .game card_$pos2 $image2 back gray
			
		}
	
}


################################################################
# proc checkForFinished {}--
#    checks to see if the game is won.  Returns true/false
# Arguments
#   
# 
# Results
# 
# 

proc checkForFinished {} {
	global concentration
	if {[expr $concentration(player,score) + $concentration(computer,score)] == 24} {
		return TRUE
	} else {
		return FALSE
	}
}

################################################################
# proc endGame {}--
#    Provide end of game display and 
#    ask about a new game
# 
# Arguments
#   NONE
# 
# Results
#   GUI is modified
# 

proc endGame {} {
	global concentration
	
	#set numberOfCards [llength $concentration(cards)]
	
	for {set pos 0} {$pos < [llength $concentration(cards)]} {incr pos} {
		.game itemconfigure card_$pos -image [lindex $concentration(cards) $pos]
	}
	
	update idle
	after 2000
	
	.game create rectangle 350 250 550 400 -fill blue \
		-stipple gray50 -width 3 -outline gray
	
	button .bAgain -text "Play Again" -command {
		destroy .bAgain
		destroy .bQuit
		startGame
	}
	
	button .bQuit -text "Quit" -command "exit"
	
	.game create window 450 300 -window .bAgain
	.game create window 450 350 -window .bQuit
	
}

# Call the one time procedures here and start game

loadImages
makeGameBoard
startGame