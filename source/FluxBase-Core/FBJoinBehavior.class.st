Class {
	#name : 'FBJoinBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'as yet unclassified' }
FBJoinBehavior >> execute [
	| joinState |
	activation value: self argument.
	joinState := activation instance
		joinStateFor: activation node
		splitId: activation token splitId.
	"key each arrival by the node it came from, so the branches stay distinguishable
	and the join's own output reads as sourceNode -> value"
	joinState arrived at: activation sourceNode put: self argument.
	activation done.
	(joinState arrived size >= joinState expected size) ifTrue: [
		activation value: joinState arrived.
		activation followAllOutgoing ]
]
