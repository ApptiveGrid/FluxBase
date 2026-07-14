Extension { #name : 'FBBaseActivation' }

{ #category : '*FluxBase-Roassal' }
FBBaseActivation >> stateBorder [
	| map border |
	map := {
		#created -> Color gray.
		#running -> Color blue.
		#waiting -> Color orange.
		#done -> Color green.
		#error -> Color red } asDictionary.
	border := RSBorder new
		width: 2;
		color: ((map at: state)  alpha: 0.8).
	(state = #waiting) ifTrue: [ border dashArray: #( 2 ) ].
	^ border

]
