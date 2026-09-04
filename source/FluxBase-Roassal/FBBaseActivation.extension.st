Extension { #name : 'FBBaseActivation' }

{ #category : '*FluxBase-Roassal' }
FBBaseActivation >> stateBorder [
	"through #state, not the ivar: #waiting no longer lives there, it comes off the
	token - see FBBaseActivation>>state"
	| map border currentState |
	map := {
		#created -> Color gray.
		#running -> Color blue.
		#waiting -> Color orange.
		#done -> Color green.
		#error -> Color red } asDictionary.
	currentState := self state.
	border := RSBorder new
		width: 2;
		color: ((map at: currentState) alpha: 0.8).
	(currentState = #waiting) ifTrue: [ border dashArray: #( 2 ) ].
	^ border

]
