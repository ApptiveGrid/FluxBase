Class {
	#name : 'FBWaitForConditionBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'execution' }
FBWaitForConditionBehavior >> execute [
	(self node evaluateConditionWith: activation argument)
		ifTrue: [ activation followAll: self node outgoing ]
		ifFalse: [ activation waitForNode: self node ]
]
