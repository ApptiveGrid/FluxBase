Class {
	#name : 'FBScopeTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBScopeTest >> testAccessorsRoundTrip [
	| scope node |
	node := FBTask named: 'owner'.
	scope := FBScope new.
	scope
		parentId: 'parent-1';
		ownerNode: node;
		tokens: (OrderedCollection with: FBToken new);
		state: #cancelled;
		cancellationPolicy: #cascade.
	self assert: scope parentId equals: 'parent-1'.
	self assert: scope ownerNode equals: node.
	self assert: scope tokens size equals: 1.
	self assert: scope state equals: #cancelled.
	self assert: scope cancellationPolicy equals: #cascade
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
