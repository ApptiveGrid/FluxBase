Class {
	#name : 'FBAndSplitBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'execution' }
FBAndSplitBehavior >> execute [
	"one pass through the split: open its FBSplitExecution with as many branches as I
	start, and send every branch off on its own token of that pass"
	| split |
	activation value: self argument.
	activation done.
	split := FBSplitExecution openedBy: activation branchCount: activation node outgoing size.
	activation node outgoing do: [ :transition |
		activation followTransition: transition withToken: (
			activation childToken
				split: split;
				yourself) ]
]
