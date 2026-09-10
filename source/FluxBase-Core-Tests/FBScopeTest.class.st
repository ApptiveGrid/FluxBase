Class {
	#name : 'FBScopeTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBScopeTest >> testAccessorsRoundTrip [
	| scope node enclosing |
	node := FBTask named: 'owner'.
	enclosing := FBScope new.
	scope := FBScope new.
	scope
		outer: enclosing;
		ownerNode: node;
		state: #cancelled.
	self assert: scope outer equals: enclosing.
	self assert: scope ownerNode equals: node.
	self assert: scope state equals: #cancelled
]

{ #category : 'as yet unclassified' }
FBScopeTest >> testChildOwnedByNestsInsideTheReceiver [
	| node root child |
	node := FBTask named: 'owner'.
	root := FBScope rootOwnedBy: nil.
	child := root childOwnedBy: node.
	self assert: child outer equals: root.
	self assert: child ownerNode equals: node.
	self deny: child id equals: root id
]

{ #category : 'as yet unclassified' }
FBScopeTest >> testDepthIsDerivedFromTheOuterChain [
	"depth is not stored - it is counted by walking #outer, so it cannot disagree
	with the actual nesting. Reparenting a scope changes its depth immediately."
	| root inner innermost |
	root := FBScope rootOwnedBy: nil.
	inner := root childOwnedBy: nil.
	innermost := inner childOwnedBy: nil.
	self assert: root depth equals: 0.
	self assert: inner depth equals: 1.
	self assert: innermost depth equals: 2.
	innermost outer: root.
	self assert: innermost depth equals: 1
]

{ #category : 'as yet unclassified' }
FBScopeTest >> testNewScopeHasActiveStateAndUniqueId [
	"a scope stores no membership: which tokens live in it is read off the executors'
	bookkeeping (FBFlowInstance>>isScopeLive:), so there is no #tokens to be empty"
	| a b |
	a := FBScope new.
	b := FBScope new.
	self assert: a state equals: #active.
	self assert: a id notNil.
	self deny: a id equals: b id
]

{ #category : 'as yet unclassified' }
FBScopeTest >> testCallDepthCountsOnlyTheScopesASubFlowCallOpened [
	"the recursion guard compares calls, not nesting: an iteration of a parallel node
	nests a scope without being a call, and a hundred iterations must not read as a
	hundred levels of recursion"
	| root call iteration nestedCall |
	root := FBScope rootOwnedBy: nil.
	call := root childOwnedBy: FBSubFlowNode new.
	iteration := call childOwnedBy: (FBParallelNode named: 'fork').
	nestedCall := iteration childOwnedBy: FBSubFlowNode new.
	self assert: (root depth -> root callDepth) equals: 0 -> 0.
	self assert: (call depth -> call callDepth) equals: 1 -> 1.
	self assert: (iteration depth -> iteration callDepth) equals: 2 -> 1.
	self assert: (nestedCall depth -> nestedCall callDepth) equals: 3 -> 2
]

{ #category : 'as yet unclassified' }
FBScopeTest >> testEnclosesItselfAndWhatIsNestedInIt [
	| root inner other |
	root := FBScope rootOwnedBy: nil.
	inner := (root childOwnedBy: nil) childOwnedBy: nil.
	other := FBScope rootOwnedBy: nil.
	self assert: (root encloses: root).
	self assert: (root encloses: inner).
	self deny: (inner encloses: root).
	self deny: (root encloses: other).
	"a token from before tokens carried a scope belongs to none"
	self deny: (root encloses: nil)
]
