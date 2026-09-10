Class {
	#name : 'FBSubFlowExecutor',
	#superclass : 'FBBaseExecutor',
	#instVars : [
		'childInstance',
		'callerActivation'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'accessing' }
FBSubFlowExecutor >> atEnd [
    ^ childInstance atEnd
]

{ #category : 'accessing' }
FBSubFlowExecutor >> callerActivation [
    "the activation of the FBSubFlowNode that opened this frame. it stays open for
    the whole sub flow call and is only completed when the frame is popped"
    ^ callerActivation
]

{ #category : 'accessing' }
FBSubFlowExecutor >> callerActivation: anActivation [
    callerActivation := anActivation
]

{ #category : 'accessing' }
FBSubFlowExecutor >> childInstance [
    ^ childInstance
]

{ #category : 'accessing' }
FBSubFlowExecutor >> childInstance: aFBFlowInstance [
    childInstance := aFBFlowInstance
]

{ #category : 'private' }
FBSubFlowExecutor >> childResult [
    "the value the sub flow ended with. FBSubFlowNode>>subFlow: guarantees the sub
    flow has exactly one end node, so its end activation is unambiguous"
    ^ (childInstance rootExecutor activationOf: childInstance flow end) argument
]

{ #category : 'private' }
FBSubFlowExecutor >> failCallerWith: aMessage [
    "the sub flow errored and the caller does not model an #error transition. mark
    the calling activation as errored the way FBFlowInstance>>activateProtected:
    would have, then pop without a continuation so the caller stops.
    signalling an FBError here instead would escape uncaught: unlike the
    run-to-completion implementation this frame is stepped on its own, outside the
    caller's activateProtected: block, so nothing would record the error on the
    activation"
    callerActivation errored.
    flowInstance addEvent: (FBNodeActivationErrored new
             activation: callerActivation;
             activationError: aMessage).
    self popThenResume: [ ]
]

{ #category : 'private' }
FBSubFlowExecutor >> finish [
    "the sub flow reached its end or errored. resolve the result transition, hand
    the result to the calling activation and pop this frame off the caller's
    executor stack. the continuation is enqueued from inside popThenResume:'s
    block so that it lands on the caller's executor instead of on this frame -
    see the comment in FBBaseExecutor>>popThenResume:"
    | isError resultName matchedTransition |
    isError := childInstance hasErrors.
    resultName := isError ifTrue: [ #error ] ifFalse: [ #success ].
    matchedTransition := callerActivation node outgoing
                             detect: [ :each | each resultName = resultName ]
                             ifNone: [ nil ].
    (isError and: [ matchedTransition isNil ]) ifTrue: [
        ^ self failCallerWith:
              'sub flow ended in error and no #error transition is modelled' ].
    isError ifFalse: [ callerActivation value: self childResult ].
    self popThenResume: [
        callerActivation done.
        matchedTransition
            ifNotNil: [ callerActivation followTransition: matchedTransition ]
            ifNil: [ callerActivation followAllOutgoing ] ]
]

{ #category : 'accessing' }
FBSubFlowExecutor >> flow [
    "this frame executes the sub flow's definition, not the caller's"
    ^ childInstance flow
]

{ #category : 'testing' }
FBSubFlowExecutor >> hasPending [
    "while this frame is on the caller's executor stack it is the sub flow's own
    work queue that decides whether there is a next step to take"
    ^ childInstance executor hasPending
]

{ #category : 'accessing' }
FBSubFlowExecutor >> isDone [
    ^ childInstance atEnd
]

{ #category : 'testing' }
FBSubFlowExecutor >> isRunning [
    ^ self hasPending
]

{ #category : 'testing' }
FBSubFlowExecutor >> isSubFlow [
    ^ true
]

{ #category : 'testing' }
FBSubFlowExecutor >> isWaiting [
    "a node suspended anywhere inside the sub flow has to surface as the calling
    instance waiting, otherwise FBFlowInstance>>state reports #running for an
    instance that nothing will ever advance. Asked of the child through its own
    definition of waiting, not through its #state"
    ^ childInstance isWaiting
]

{ #category : 'printing' }
FBSubFlowExecutor >> printOn: aStream [
    aStream << 'sub flow frame depth='
        << (childInstance scope ifNil: [ '?' ] ifNotNil: [ :each | each depth asString ])
]

{ #category : 'services' }
FBSubFlowExecutor >> step [
    "advance the sub flow by exactly one node. this is what keeps a step from ever
    crossing a node boundary: entering the sub flow only pushed this frame, and
    every following step executes a single child node, so the caller's transaction
    boundary still encloses one activation. when the child ends or errors we pop,
    when it suspends on a wait we stay on the stack with nothing pending"
    childInstance step.
    (childInstance atEnd or: [ childInstance hasErrors ]) ifTrue: [
        self finish ]
]

{ #category : 'accessing' }
FBSubFlowExecutor >> suspended [
    "deliberately not delegated to the sub flow. FBFlowInstance>>resumeWaitingAt:with:
    picks its holder by searching #suspended and then mutates that very collection
    and looks up an activation in it - handing it the child's nodes would resolve
    them against the caller's activations. sub flow waits are reached through
    FBFlowInstance>>activeExecutors instead"
    ^ suspended
]

{ #category : 'cancelling' }
FBSubFlowExecutor >> settleAfterWithdrawal [
    "the strands taken out may have been the child's last: then the child is at its end
    without ever having reached its end node, and nothing would pop this frame. Until a
    cancelled scope carries that as its state (the next slice of Scope und Abbruch), the
    caller is failed the way an errored child without an #error transition fails it -
    the frame pops, the caller's activation is marked, the instance stops in #error"
    childInstance atEnd ifFalse: [ ^ self ].
    (childInstance activations anySatisfy: [ :each | each node == childInstance flow end ])
        ifTrue: [ self finish ]
        ifFalse: [ self failCallerWith: 'sub flow was cancelled before reaching its end' ]
]
