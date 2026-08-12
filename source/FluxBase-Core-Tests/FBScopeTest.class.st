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
		tokens: (OrderedCollection with: FBToken new);
		state: #cancelled;
		cancellationPolicy: #cascade.
	self assert: scope outer equals: enclosing.
	self assert: scope ownerNode equals: node.
	self assert: scope tokens size equals: 1.
	self assert: scope state equals: #cancelled.
	self assert: scope cancellationPolicy equals: #cascade
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
FBScopeTest >> testNewScopeHasActiveStateEmptyTokensAndUniqueId [
	| a b |
	a := FBScope new.
	b := FBScope new.
	self assert: a state equals: #active.
	self assert: a tokens isEmpty.
	self assert: a id notNil.
	self deny: a id equals: b id
]
