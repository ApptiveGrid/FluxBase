Class {
	#name : 'FBParallelExecutor',
	#superclass : 'FBBaseExecutor',
	#instVars : [
		'list',
		'node',
		'index',
		'map',
		'iterationScope',
		'iterationScopeIndex',
		'openIterationScopes',
		'current'
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
FBParallelExecutor >> activateTransition: aTransition with: value token: aToken [
	"aToken is the token the queued work item carried, restored onto the activation the
	way FBFlowExecutor>>step and FBBaseExecutor>>resumeWith: do. The activation itself
	is cached per transition (see #newActivation:), so it is reused across the
	iterations of this scope and the token has to be reset for each of them - a join
	inside the scope reads #splitId off it while that iteration is running"

	| activation |
	activation := self newActivation: aTransition.
	aToken ifNotNil: [ :token | activation token: token ].
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
    self closeFinishedIterations.
    self isInCancelledScope ifTrue: [
        "the scope my loop runs in was cancelled: no further iteration starts, and what
        was queued for the current one falls. Nothing follows the fork either - the
        scope join never runs, and a token of a cancelled scope queues nothing"
        pending removeAll: pending copy.
        index := list size ].
    (pending isEmpty and: [ index < list size ]) ifTrue: [
        index := index + 1.
        self queueScopeBody ].
    pending isEmpty ifFalse: [ ^ self ].
    suspended isEmpty ifFalse: [ ^ self ].
    self completeScope
]

{ #category : 'services' }
FBParallelExecutor >> completeScope [
	"the loop is over - every iteration accounted for: arrived at the scope join,
	filtered by a condition, or taken back (#atEnd) - and closes the way its scope join
	closes it, whoever accounted for the last iteration: the join's own step
	(FBParallelJoinNodeBehavior), a withdrawal (#settleAfterWithdrawal), a filtered last
	iteration or an empty input (#continue). Before, only the join's own step closed the
	scope; the other endings popped me and left the flow behind the loop unrun, while
	the instance read #done.

	I am popped, the fork is done, and the scope join's activation carries one value per
	iteration - nil where none arrived - and goes on behind the join on a token of the
	fork's strand: behind the loop the strand is the fork's again, in the fork's scope,
	not in the last iteration's. The loop completes with nothing as well - an empty
	input, every iteration filtered, every iteration taken back: the flow behind it goes
	on with an empty result, since the loop is one activity of the flow and not a join of
	independent strands (Norbert, 2026-09-10; an AND-join with nothing arrived releases
	nothing, see FBJoinState>>canRelease). A loop whose own scope was cancelled queues
	nothing here (FBBaseExecutor>>addPending:withToken:).

	A body that ends the strand instead - every path through it reaching an end event -
	has no join to go on from (#scopeJoinNode answers nil): the scope closes and that is
	the end of the fork's strand, as it is when every branch of a split ends"

	| fork join |
	fork := self activationOf: node.
	join := self scopeJoinActivation.
	self popThenResume: [
		fork done.
		join ifNotNil: [
			join values: join arguments.
			join token: fork childToken.
			join done.
			join followAllOutgoing ] ]
]

{ #category : 'services' }
FBParallelExecutor >> scopeJoinActivation [
	"the activation of my scope join - the one the iterations arrived at, or a fresh one
	when none did (#completeScope with nothing arrived); nil for a body without a join
	to go on from"
	| join |
	join := self scopeJoinNode ifNil: [ ^ nil ].
	^ self activations reverse
		detect: [ :each | each node == join and: [ each executor == self ] ]
		ifNone: [ self activations add: (self newActivation node: join; yourself) ]
]

{ #category : 'services' }
FBParallelExecutor >> scopeJoinNode [
	"the node that closes my scope: the FBParallelJoinNode of my fork - the first one
	reachable from the body at my own nesting level, an inner loop's join being passed
	with that loop - or, when the body closes the scope implicitly, the join synthesized
	for it (#impliedContinuationNode, see FBNode>>effectiveOutgoingFor:) - or nil, when
	every path through the body ends the strand at a flow terminal (an end event inside
	the loop) and there is nothing behind the loop to go on to. Asked when the scope
	completes without an arrival, which is the one moment no iteration has led the way"
	| seen frontier openLeaf |
	openLeaf := false.
	seen := IdentitySet new.
	frontier := OrderedCollection new.
	node outgoing do: [ :each | frontier add: each target -> 0 ].
	[ frontier isEmpty ] whileFalse: [
		| pair candidate depth |
		pair := frontier removeFirst.
		candidate := pair key.
		depth := pair value.
		(seen includes: candidate) ifFalse: [
			seen add: candidate.
			(candidate isKindOf: FBParallelJoinNode) ifTrue: [
				depth = 0 ifTrue: [ ^ candidate ].
				depth := depth - 1 ].
			(candidate isKindOf: FBParallelNode) ifTrue: [ depth := depth + 1 ].
			candidate outgoing
				ifEmpty: [ candidate isFlowTerminal ifFalse: [ openLeaf := true ] ]
				ifNotEmpty: [ :outgoing | outgoing do: [ :each | frontier add: each target -> depth ] ] ] ].
	^ openLeaf ifTrue: [ self impliedContinuationNode ] ifFalse: [ nil ]
]

{ #category : 'execution' }
FBParallelExecutor >> execute [ 
	[   
		[ pending isEmpty ] whileFalse: [
			self step ].
		index := index + 1.
		(index > list size) ifTrue: [ ^ self ].
		self queueScopeBody. 
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
FBParallelExecutor >> iterationOf: aToken [
	"the slot of the iteration aToken belongs to, read off the iteration scope its scope
	lies in (FBScope>>iterationOwnedBy:). This is what an activation that runs late has
	to write into and read from: a wait resumed after the loop went on to the next
	iteration, whose step comes when #index already points further. A token without a
	scope - persisted before iterations had one - or with none of mine falls back to
	the cursor, which is right whenever iterations do not overlap"
	aToken ifNil: [ ^ index ].
	^ (aToken scope ifNotNil: [ :scope | scope iterationOwnedBy: node ])
		ifNil: [ index ]
		ifNotNil: [ :iteration | iteration index ]
]

{ #category : 'accessing' }
FBParallelExecutor >> currentIteration [
	"the iteration whose step or resume is running - what the loop variable and a
	predecessor's value are read for (#lastValueOf:, #outputFor:). #index is not that:
	it is the newest iteration queued, and the loop moves on to the next one while an
	earlier one still waits. Set by #step from the work item's token and by
	#resume:withToken:value: from the token going on; the cursor before any step"
	^ current ifNil: [ index ]
]

{ #category : 'executing' }
FBParallelExecutor >> resume: aSuspension withToken: aToken value: aValue [
	"a resume is a step of the iteration whose token goes on: what runs now reads the
	loop off that iteration, see #currentIteration. A resume that names no token - the
	oldest parked one goes on - reads off the cursor, as before"
	current := self iterationOf: aToken.
	^ super resume: aSuspension withToken: aToken value: aValue
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
	aFBNode == node ifTrue: [ ^ list at: self currentIteration ].
	activation := self activationOf: aFBNode.
	^ (activation executor == self)
		ifTrue: [ activation value at: self currentIteration ]
		ifFalse: [ activation value ]
]

{ #category : 'accessing' }
FBParallelExecutor >> list: aCollection [
	"the input I iterate. An empty one has no iteration: the seed #node: queued falls
	out of #pending again, and the cursor stands at 0 so that #atEnd holds - the fork's
	behavior sends #continue right after pushing me, and the scope completes at once
	with an empty result (#completeScope)"
	list := aCollection.
	aCollection isEmpty ifTrue: [
		pending removeAll: pending copy.
		index := 0 ]
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
	self queueScopeBody
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
		^ list at: self currentIteration ].
	(self activationOf: node) isDone ifTrue: [ ^ anActivation value first ].
	^ anActivation value at: (self iterationOf: anActivation token)
]

{ #category : 'private' }
FBParallelExecutor >> queueScopeBody [
	"queue this scope's body - the fork's outgoing transitions - for the iteration
	being entered. All three places that start an iteration come through here (#node:
	for the first one, #continue and #execute for the ones after it) so that none of
	them writes into #pending itself: every entry there is an FBWorkItem, and a
	transition put in raw would reach #step without the token it has to run under.
	No token is minted here, see #scopeToken"

	node outgoing do: [ :transition | self addPending: transition ]
]

{ #category : 'services' }
FBParallelExecutor >> resumeAfter: anExecutor [
    self continue
]

{ #category : 'private' }
FBParallelExecutor >> scopeToken [
	"the token the head of this scope's body runs under for the iteration being
	entered: a child token of the fork's own activation, which is exactly what
	FBBaseActivation>>followAllOutgoing would have handed out had the fork's outgoing
	transitions been followed outside a parallel scope - living in the iteration's own
	scope (#currentIterationScope). A fresh one per iteration, so two passes through a
	split inside the scope are two split executions and each gets its own FBJoinState.

	Minted in #step rather than in #queueScopeBody because #node: - the first of the
	three places that queue the body - runs before FBFlowInstance>>pushExecutor: has
	given this executor its flow instance, so the fork's activation is not reachable
	yet at queueing time. Everything else in #pending was put there by
	FBBaseActivation>>followTransition:withToken: and carries its own token, which is
	what makes a missing one identify a body seed"

	^ (self activationOf: node) childToken
		scope: self currentIterationScope;
		yourself
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
	| workItem transition lastValue |
	workItem := pending removeFirst.
	transition := workItem transition.
	"the iteration this step belongs to, read off the work item's token: a body seed
	(no token yet, see #scopeToken) is the newest iteration's, everything else carries
	the token of the iteration that queued it"
	current := workItem token ifNil: [ index ] ifNotNil: [ :token | self iterationOf: token ].
	lastValue := transition source lastValueIn: self.

	(self shouldFollowTransition: transition with: lastValue) ifTrue: [
		self
			activateTransition: transition
			with: lastValue
			token: (workItem token ifNil: [ self scopeToken ]) ].

	"In case this executor is the current one we continue. If another 
	executor has been pushed we just return to be suspended an continued
	after the child executor has been popped"
   flowInstance executor == self
        ifTrue: [ self continue ].

    
]

{ #category : 'private' }
FBParallelExecutor >> currentIterationScope [
	"the scope of the iteration being entered, opened on first ask per iteration and
	nested in the scope the fork itself runs in. One per iteration, however many
	outgoing transitions the fork has: #scopeToken is sent once per body seed"
	iterationScopeIndex = index ifTrue: [ ^ iterationScope ].
	iterationScope := ((self activationOf: node) token scope
		ifNil: [ flowInstance ensureScope ]) childOwnedBy: node.
	iterationScope index: index.
	iterationScopeIndex := index.
	openIterationScopes ifNil: [ openIterationScopes := OrderedCollection new ].
	openIterationScopes add: iterationScope.
	^ iterationScope
]

{ #category : 'private' }
FBParallelExecutor >> closeFinishedIterations [
	"an iteration is over when nothing runs or waits in its scope any more - not when
	the next one starts, since an iteration may still wait at a form while later ones
	run. Asked whenever this executor continues, so an iteration's join states and
	addresses fall as soon as it is done (FBFlowInstance>>scopeEnded:), which is what
	keeps a long loop from piling up the bookkeeping of every pass until the instance
	ends"
	openIterationScopes ifNil: [ ^ self ].
	(openIterationScopes reject: [ :each | flowInstance isScopeLive: each ]) do: [ :each |
		flowInstance scopeEnded: each.
		openIterationScopes remove: each ]
]

{ #category : 'testing' }
FBParallelExecutor >> isDone [
	"done only when I am at the end of my list, not whenever my queues happen to be
	empty: between two iterations, and while a frame pushed by my body runs, nothing is
	pending or suspended here although the loop is far from over. Without this the
	inherited answer said #done in the middle of the loop"
	^ self atEnd
]

{ #category : 'cancelling' }
FBParallelExecutor >> settleAfterWithdrawal [
	"go on the way #step would have: close finished iterations, start the next one, or
	stop when the list is done and nothing waits. Only while I am the executor on top -
	below a frame the frame's popping resumes me anyway (#resumeAfter:)"
	flowInstance executor == self ifTrue: [ self continue ]
]

{ #category : 'testing' }
FBParallelExecutor >> isInCancelledScope [
	"does my loop run in a cancelled scope? Read off the fork's own token; an iteration
	scope cancelled on its own does not stop the loop, only that iteration"
	^ (self activationOf: node) token isInCancelledScope
]
