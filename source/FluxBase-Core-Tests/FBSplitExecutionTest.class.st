Class {
	#name : 'FBSplitExecutionTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBSplitExecutionTest >> testAPassOpenedByAnActivationNestsInItsTokensPassAndScope [
	| scope outerPass activation pass |
	scope := FBScope rootOwnedBy: nil.
	outerPass := FBSplitExecution new.
	activation := FBActivation new.
	activation node: (FBAndSplit named: 'split').
	activation token scope: scope; split: outerPass.
	pass := FBSplitExecution openedBy: activation branchCount: 3.
	self assert: pass node identicalTo: activation node.
	self assert: pass outer identicalTo: outerPass.
	self assert: pass scope identicalTo: scope.
	self assert: pass branchCount equals: 3.
	self assert: pass id notNil.
	self deny: pass id equals: outerPass id
]

{ #category : 'tests' }
FBSplitExecutionTest >> testAMultiChoicePassCountsOnlyTheBranchesItStarted [
	"the join behind a multi choice waits for the branches whose condition held, not
	for every transition into it"
	| start choice a b join end flow instance pass |
	start := FBStartEvent new.
	choice := start addOutgoingNode: (FBMultiChoiceGateway named: 'choice').
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBOrJoin named: 'join'.
	choice --> (a when: [ :x | x > 0 ]) --> join.
	choice --> (b when: [ :x | x > 100 ]) --> join.
	end := join addOutgoingNode: FBEndEvent new.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance executeWith: 1.
	pass := (instance activationOfNode: a) token split.
	self assert: pass branchCount equals: 1.
	self assert: instance state equals: #done.
	self assert: (instance activations select: [ :act | act node = end ]) size equals: 1
]
