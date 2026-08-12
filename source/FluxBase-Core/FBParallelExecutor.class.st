Class {
	#name : 'FBParallelExecutor',
	#superclass : 'FBBaseExecutor',
	#instVars : [
		'list',
		'node',
		'index',
		'map'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'accessing' }
FBParallelExecutor >> activate: activation [

	"unlike default behavior, the activation is already added to the list when being instantiated.
	here we only take care of the execution part"
	flowInstance activateProtected: activation 
]

{ #category : 'private' }
FBParallelExecutor >> activateTransition: aTransition with: value [

	| activation |
	activation := self newActivation: aTransition.
	activation argument: value.
	self activate: activation
]

{ #category : 'accessing' }
FBParallelExecutor >> activationClass [
	^ node activationClass
]

{ #category : 'accessing' }
FBParallelExecutor >> atEnd [
	^((index = list size) and: [ pending isEmpty ])and:[suspended isEmpty]
]

{ #category : 'services' }
FBParallelExecutor >> buildImpliedContinuationNode [
	^ node impliedJoinNodeClass new
]

{ #category : 'services' }
FBParallelExecutor >> continue [
    (pending isEmpty and: [ index < list size ]) ifTrue: [
        index := index + 1.
        pending addAll: node outgoing ].

    pending isEmpty ifFalse: [ ^ self ].

    suspended isEmpty ifFalse: [ ^ self ].

    (self activationOf: node) done.
    self stop
]

{ #category : 'execution' }
FBParallelExecutor >> execute [ 
	[   
		[ pending isEmpty ] whileFalse: [
			self step ].
		index := index + 1.
		(index > list size) ifTrue: [ ^ self ].
		pending addAll: node outgoing. 
 	] repeat
]

{ #category : 'accessing' }
FBParallelExecutor >> index [
	^ index
]

{ #category : 'initialization' }
FBParallelExecutor >> initialize [ 
	super initialize.
	index := 1.
	map := Dictionary new 

]

{ #category : 'testing' }
FBParallelExecutor >> isLastIndex [

	^ index = list size
]

{ #category : 'testing' }
FBParallelExecutor >> isParallel [

	^ true
]

{ #category : 'accessing' }
FBParallelExecutor >> lastValueOf: aFBNode [
	"resolve aFBNode's value for the iteration this executor is currently on.
	when aFBNode's activation was created by this same executor (e.g. a task
	directly inside this parallel scope), its values are one slot per iteration
	of *this* list, so the current slot needs to be picked out explicitly.
	when aFBNode is a join terminating a *nested* parallel scope though, its
	activation was created by that (smaller/differently-sized) inner executor,
	and its value is already the fully resolved result for this iteration - so
	it must be used as-is rather than sliced again with this executor's index
	(see FBParallelJoinNodeBehavior, and the FluxBase 'nested parallel node'
	ticket this fixes)"
	| activation |
	aFBNode == node ifTrue: [ ^ list at: index ].
	activation := self activationOf: aFBNode.
	^ (activation executor == self)
		ifTrue: [ activation value at: index ]
		ifFalse: [ activation value ]
]

{ #category : 'accessing' }
FBParallelExecutor >> list: aCollection [ 
	list := aCollection.

]

{ #category : 'instance creation' }
FBParallelExecutor >> newActivation [
	^ self activationClass new
		executor: self;
		initializeValues: list size 
]

{ #category : 'stepping' }
FBParallelExecutor >> newActivation: transition [
	^ map 
		at: transition
		ifAbsentPut: [ 
			self activations add: (self newActivation 
				node: transition target) ]
]

{ #category : 'accessing' }
FBParallelExecutor >> node [
	^ node 
]

{ #category : 'accessing' }
FBParallelExecutor >> node: aFBParallelNode [ 
	node := aFBParallelNode.
	pending addAll: node outgoing 
]

{ #category : 'services' }
FBParallelExecutor >> outputFor: anActivation [
	"two distinct callers reach this method with two distinct meanings:
	- a regular task's activation, created inside this executor's own scope
	  (anActivation node ~= self node): its #value holds one slot per iteration of this
	  scope, so it has to be sliced with this executor's index.
	- this same parallel node's own self-activation (anActivation node == self node):
	  #list and #index are the loop this node is running, so they are the authoritative
	  answer - and the only one that tracks the iteration. that matters beyond display:
	  a parallel node's #output is the loop variable scripts read, so a loop body's
	  branch conditions and output scripts depend on it advancing (see
	  AGParallelNodeTest>>testExecuteWithCondition and #testExecuteWithOutputScript).
	  #value cannot serve here, since for a node nested in an enclosing parallel scope it
	  holds one slot per *outer* iteration.

	this is reached only while the scope is open, because FBFlowInstance>>executors is the
	live stack - which is what stopped #parallelExecutorFrom:ifAbsent: from handing out a
	finished executor of an earlier outer iteration and freezing the output there
	(FBFlowTest>>testNestedParallelNodeInnerForkOutputFollowsRunningIteration)"

	self node == anActivation node ifTrue: [
		(self activationOf: node) isDone ifTrue: [ ^ list first ].
		^ list at: index ].
	(self activationOf: node) isDone ifTrue: [ ^ anActivation value first ].
	^ anActivation value at: self index
]

{ #category : 'services' }
FBParallelExecutor >> resumeAfter: anExecutor [
    self continue
]

{ #category : 'private' }
FBParallelExecutor >> shouldFollowTransition: transition with: value [
	"this parallel executor has been instantiated right after activating a parallel node.
	the transition following the parallel node may have condition.
	we make sure that this condition is evaluated before activating a given iteration value"

	transition source = node ifFalse: [ ^ true ].
	^ (self activationOf: node) shouldFollowTransition: transition with: value
]

{ #category : 'services' }
FBParallelExecutor >> step [
	| transition lastValue |
	transition := pending removeFirst.
	lastValue := transition source lastValueIn: self.

	(self shouldFollowTransition: transition with: lastValue) ifTrue: [
		self activateTransition: transition with: lastValue ].

	"In case this executor is the current one we continue. If another 
	executor has been pushed we just return to be suspended an continued
	after the child executor has been popped"
   flowInstance executor == self
        ifTrue: [ self continue ].

    
]
