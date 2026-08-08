Class {
	#name : 'FBSubFlowNodeTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBSubFlowNodeTest >> testParentTracksItsSubFlowInstancesButChildHasNoBackReference [
    | childStart childFlow parentStart subNode parentFlow instance childInstance |
    childStart := FBStartEvent new.
    childStart addOutgoingNode: FBEndEvent new.
    childFlow := FBFlow new start: childStart.

    parentStart := FBStartEvent new.
    subNode := parentStart addOutgoingNode: FBSubFlowNode new.
    subNode subFlow: childFlow.
    subNode addOutgoingNode: FBEndEvent new.
    parentFlow := FBFlow new start: parentStart.

    instance := parentFlow newInstance.
    instance executeWith: 1.
    self assert: instance subFlowInstances size equals: 1.
    childInstance := instance subFlowInstances first.
    self assert: childInstance flow equals: childFlow.
    self deny: (childInstance class allInstVarNames includes: 'parent')
]

{ #category : 'tests' }
FBSubFlowNodeTest >> testSubFlowExecutesNestedFlowAndReturnsItsEndValue [
    | childStart double childFlow parentStart subNode parentFlow instance |
    childStart := FBStartEvent new.
    double := childStart addOutgoingNode: ((FBPluggableTask named: 'double') block: [ :a | a value: a argument * 2 ]).
    double addOutgoingNode: FBEndEvent new.
    childFlow := FBFlow new start: childStart.

    parentStart := FBStartEvent new.
    subNode := parentStart addOutgoingNode: FBSubFlowNode new.
    subNode subFlow: childFlow.
    subNode addOutgoingNode: FBEndEvent new.
    parentFlow := FBFlow new start: parentStart.

    instance := parentFlow newInstance.
    instance executeWith: 21.
    self assert: instance atEnd.
    self assert: instance state equals: #done.
    self assert: ((instance rootExecutor activationOf: parentFlow end) argument) equals: 42
]

{ #category : 'tests' }
FBSubFlowNodeTest >> testSubFlowPropagatesAsGenericErrorWhenNoErrorTransitionIsModelled [
    | childStart failing childFlow parentStart subNode parentFlow instance |
    childStart := FBStartEvent new.
    failing := childStart addOutgoingNode: (FBErrorTestTask named: 'boom').
    failing addOutgoingNode: FBEndEvent new.
    childFlow := FBFlow new start: childStart.

    parentStart := FBStartEvent new.
    subNode := parentStart addOutgoingNode: FBSubFlowNode new.
    subNode subFlow: childFlow.
    subNode addOutgoingNode: FBEndEvent new.
    parentFlow := FBFlow new start: parentStart.

    instance := parentFlow newInstance.
    instance executeWith: 1.
    self assert: instance state equals: #error
]

{ #category : 'tests' }
FBSubFlowNodeTest >> testSubFlowRecursionGuardStopsAtMaxDepth [
    | flow start subNode instance |
    flow := FBFlow new.
    start := FBStartEvent new.
    subNode := start addOutgoingNode: FBSubFlowNode new.
    subNode maxDepth: 2.
    subNode addOutgoingNode: FBEndEvent new.
    flow start: start.
    subNode subFlow: flow.

    instance := flow newInstance.
    self should: [ instance executeWith: 1 ] raise: FBSubFlowMaxDepthExceeded
]

{ #category : 'tests' }
FBSubFlowNodeTest >> testSubFlowRejectsFlowsWithMoreThanOneEndNodeAtWiringTime [
    | start gateway a b flow subNode |
    start := FBStartEvent new.
    gateway := FBExclusiveGateway named: 'g'.
    a := FBTask named: 'a'.
    b := FBTask named: 'b'.
    start --> gateway.
    gateway --> (a when: [ :x | x >= 5 ]) --> FBEndEvent new.
    gateway --> (b when: [ :x | x < 5 ]) --> FBEndEvent new.
    flow := FBFlow new start: start.
    subNode := FBSubFlowNode new.
    self should: [ subNode subFlow: flow ] raise: FBSubFlowInvalidTarget
]

{ #category : 'tests' }
FBSubFlowNodeTest >> testSubFlowRoutesToErrorTransitionWhenChildInstanceErrors [
    | childStart failing childFlow parentStart subNode onSuccess onError parentFlow instance |
    childStart := FBStartEvent new.
    failing := childStart addOutgoingNode: (FBErrorTestTask named: 'boom').
    failing addOutgoingNode: FBEndEvent new.
    childFlow := FBFlow new start: childStart.

    parentStart := FBStartEvent new.
    subNode := parentStart addOutgoingNode: FBSubFlowNode new.
    subNode subFlow: childFlow.
    onSuccess := FBEndEvent new.
    onError := FBEndEvent new.
    subNode --> (onSuccess resultTransition: #success).
    subNode --> (onError resultTransition: #error).
    parentFlow := FBFlow new start: parentStart.

    instance := parentFlow newInstance.
    instance executeWith: 1.
    self assert: instance atEnd.
    self assert: instance state equals: #done.
    self assert: (instance rootExecutor activationOf: onError) node equals: onError.
    self should: [ instance rootExecutor activationOf: onSuccess ] raise: Error
]
