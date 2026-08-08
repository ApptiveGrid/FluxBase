Class {
	#name : 'FBSubFlowBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core',
	#package : 'FluxBase-Core'
}

{ #category : 'private' }
FBSubFlowBehavior >> buildChildScope [
    "answer a new scope for the sub flow call, one level deeper than the calling flow instance's current scope. signals FBSubFlowMaxDepthExceeded if that would exceed the node's configured maxDepth"
    | parentScope |
    parentScope := activation flowInstance scope.
    parentScope depth + 1 > self node maxDepth
        ifTrue: [ FBSubFlowMaxDepthExceeded signal: 'sub flow call depth exceeds maximum of ', self node maxDepth printString ].
    ^ parentScope childOwnedBy: self node
]

{ #category : 'execution' }
FBSubFlowBehavior >> execute [
    | childScope childInstance isError resultName matchedTransition |
    childScope := self buildChildScope.
    childInstance := self node subFlow newInstance.
    childInstance scope: childScope.
    activation flowInstance addSubFlowInstance: childInstance.
    childInstance executeWith: self argument.
    isError := childInstance state = #error.
    resultName := isError ifTrue: [ #error ] ifFalse: [ #success ].
    matchedTransition := self outgoing detect: [ :t | t resultName = resultName ] ifNone: [ nil ].
    isError
        ifTrue: [
            matchedTransition ifNil: [ ^ FBError signal: 'sub flow ended in error and no #error transition is modelled' ].
            activation done.
            ^ self followTransition: matchedTransition ].
    self value: (childInstance rootExecutor activationOf: childInstance flow end) argument.
    activation done.
    matchedTransition
        ifNotNil: [ self followTransition: matchedTransition ]
        ifNil: [ activation followAll: self outgoing ]
]
