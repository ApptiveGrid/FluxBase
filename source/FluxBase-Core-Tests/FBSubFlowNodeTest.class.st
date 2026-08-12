Class {
	#name : 'FBSubFlowNodeTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'private' }
FBSubFlowNodeTest >> flowCalling: aFlow [
    "a parent flow shaped start -> sub flow node calling aFlow -> end"
    | start subNode |
    start := FBStartEvent new.
    subNode := start addOutgoingNode: FBSubFlowNode new.
    subNode subFlow: aFlow.
    subNode addOutgoingNode: FBEndEvent new.
    ^ FBFlow new start: start
]

{ #category : 'private' }
FBSubFlowNodeTest >> flowWaitingForever [
    "a flow shaped start -> wait that never becomes true -> end"
    | start wait |
    start := FBStartEvent new.
    wait := start addOutgoingNode: (FBPluggableWait new condition: [ :each | false ]; yourself).
    wait addOutgoingNode: FBEndEvent new.
    ^ FBFlow new start: start
]

{ #category : 'tests' }
FBSubFlowNodeTest >> testEnteringSubFlowOnlyPushesAFrameAndRunsNoChildNode [
    "the step that activates the sub flow node must not execute anything inside the
    sub flow. if it did, that single step - and with it a single transaction - would
    span two node executions"
    | childStart childFlow instance |
    childStart := FBStartEvent new.
    childStart addOutgoingNode: FBEndEvent new.
    childFlow := FBFlow new start: childStart.

    instance := (self flowCalling: childFlow) newInstance.
    instance initialValue: 1.
    [ instance executor isSubFlow ] whileFalse: [ instance step ].

    self assert: instance executor childInstance activations isEmpty.
    self assert: instance state equals: #running
]

{ #category : 'tests' }
FBSubFlowNodeTest >> testInnermostWaitingExecutorReachesIntoTheSubFlow [
    "while a sub flow call is open #executor is the FBSubFlowExecutor frame, whose own
    #suspended is empty by design - so asking it where execution stopped answers
    nothing for an instance that is in fact blocked. #innermostWaitingExecutor has to
    find the child instance's waiting executor instead"
    | childFlow instance |
    childFlow := self flowWaitingForever.
    instance := (self flowCalling: childFlow) newInstance.
    instance executeWith: 1.

    self assert: instance state equals: #waiting.
    self assert: instance executor suspended isEmpty.
    self deny: instance innermostWaitingExecutor == instance executor.
    self
        assert: instance innermostWaitingExecutor suspended asArray
        equals: instance suspended asArray
]

{ #category : 'tests' }
FBSubFlowNodeTest >> testSubFlowCallCreatesTheCallersRootScope [
    "the caller has no scope until a sub flow call needs one - FBSubFlowBehavior>>buildChildScope
    creates it there, rather than a lazy #scope getter creating it on any read (see
    FBFlowInstanceTest>>testReadingScopeCreatesNoScope). the depth chain has to come out
    the same either way"
    | childStart childFlow instance |
    childStart := FBStartEvent new.
    childStart addOutgoingNode: FBEndEvent new.
    childFlow := FBFlow new start: childStart.

    instance := (self flowCalling: childFlow) newInstance.
    self assert: instance scope isNil.
    instance executeWith: 1.

    self assert: instance scope notNil.
    self assert: instance scope depth equals: 0.
    self assert: instance subFlowInstances first scope depth equals: 1
]

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
FBSubFlowNodeTest >> testResumingWaitInsideSubFlowFinishesTheWholeFlow [
    | childFlow parentFlow instance wait |
    childFlow := self flowWaitingForever.
    parentFlow := self flowCalling: childFlow.

    instance := parentFlow newInstance.
    instance executeWith: 1.
    wait := instance suspended first.

    instance resumeWaitingAt: wait with: 7.
    instance execute.

    self assert: instance atEnd.
    self assert: instance state equals: #done.
    self assert: (instance rootExecutor activationOf: parentFlow end) argument equals: 7
]

{ #category : 'tests' }
FBSubFlowNodeTest >> testSubFlowAdvancesByExactlyOneChildNodePerStep [
    "one step must never cross a node boundary, not even while the flow is inside a
    sub flow: this is what lets a caller wrap every single step in its own
    transaction. the sub flow's activation count therefore has to grow by exactly
    one per step for as long as the frame is on the stack"
    | childStart first childFlow instance childInstance counts |
    childStart := FBStartEvent new.
    first := childStart addOutgoingNode:
                 ((FBPluggableTask named: 'first') block: [ :each | each value: each argument + 1 ]).
    (first addOutgoingNode:
         ((FBPluggableTask named: 'second') block: [ :each | each value: each argument + 1 ]))
        addOutgoingNode: FBEndEvent new.
    childFlow := FBFlow new start: childStart.

    instance := (self flowCalling: childFlow) newInstance.
    instance initialValue: 0.
    [ instance executor isSubFlow ] whileFalse: [ instance step ].

    counts := OrderedCollection new.
    [ instance executor isSubFlow ] whileTrue: [
        childInstance := instance executor childInstance.
        instance step.
        counts add: childInstance activations size ].

    "start, first, second, end - one activation added per step, no step doing two"
    self assert: counts equals: (1 to: 4) asOrderedCollection.
    instance execute.
    self assert: instance state equals: #done
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

{ #category : 'tests' }
FBSubFlowNodeTest >> testWaitInsideSubFlowLeavesCallingInstanceWaiting [
    "a wait modelled inside a sub flow has to surface on the calling instance,
    otherwise nothing outside can tell that the instance is blocked - or resume it"
    | childFlow instance |
    childFlow := self flowWaitingForever.

    instance := (self flowCalling: childFlow) newInstance.
    instance executeWith: 1.

    self deny: instance atEnd.
    self assert: instance state equals: #waiting.
    self assert: instance suspended size equals: 1.
    self assert: instance suspended first class equals: FBPluggableWait
]
