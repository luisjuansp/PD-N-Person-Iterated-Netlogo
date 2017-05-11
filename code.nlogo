globals [
  ;;number of turtles with each strategy
  num-random
  num-cooperate
  num-defect
  num-tit-for-tat
  num-unforgiving
  num-unknown

  ;;number of interactions by each strategy
  num-random-games
  num-cooperate-games
  num-defect-games
  num-tit-for-tat-games
  num-unforgiving-games
  num-unknown-games

  ;;total score of all turtles playing each strategy
  random-score
  cooperate-score
  defect-score
  tit-for-tat-score
  unforgiving-score
  unknown-score
]

turtles-own [
  score
  strategy
  defect-now?
  partner-defected? ;;action of the partner
  partnered?        ;;am I partnered?
  partner           ;;WHO of my partner (nobody if not partnered)
  partner-history   ;;a list containing information about past interactions
                    ;;with other turtles (indexed by WHO values)
  num-plays
]


;;;;;;;;;;;;;;;;;;;;;;
;;;Setup Procedures;;;
;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  store-initial-turtle-counts ;;record the number of turtles created for each strategy
  setup-turtles ;;setup the turtles and distribute them randomly
  reset-ticks
end

;;record the number of turtles created for each strategy
;;The number of turtles of each strategy is used when calculating average payoffs.
;;Slider values might change over time, so we need to record their settings.
;;Counting the turtles would also work, but slows the model.
to store-initial-turtle-counts
  set num-random n-random
  set num-cooperate n-cooperate
  set num-defect n-defect
  set num-tit-for-tat n-tit-for-tat
  set num-unforgiving n-unforgiving
  set num-unknown n-unknown
end

;;setup the turtles and distribute them randomly
to setup-turtles
  make-turtles ;;create the appropriate number of turtles playing each strategy
  setup-common-variables ;;sets the variables that all turtles share
end

;;create the appropriate number of turtles playing each strategy
to make-turtles
  create-turtles num-random [ set strategy "random" set color gray - 1 ]
  create-turtles num-cooperate [ set strategy "cooperate" set color red ]
  create-turtles num-defect [ set strategy "defect" set color blue ]
  create-turtles num-tit-for-tat [ set strategy "tit-for-tat" set color lime ]
  create-turtles num-unforgiving [ set strategy "unforgiving" set color turquoise - 1 ]
  create-turtles num-unknown [set strategy "unknown" set color magenta ]
end

;;set the variables that all turtles share
to setup-common-variables
  ask turtles [
    set score 0
    set partnered? false
    set partner nobody
    setxy random-xcor random-ycor
    set num-plays 0
  ]
  setup-history-lists ;;initialize PARTNER-HISTORY list in all turtles
end

;;initialize PARTNER-HISTORY list in all turtles
to setup-history-lists
  let num-turtles count turtles

  let default-history [] ;;initialize the DEFAULT-HISTORY variable to be a list

  ;;create a list with NUM-TURTLE elements for storing partner histories
  repeat num-turtles [ set default-history (fput false default-history) ]

  ;;give each turtle a copy of this list for tracking partner histories
  ask turtles [ set partner-history default-history ]
end


;;;;;;;;;;;;;;;;;;;;;;;;
;;;Runtime Procedures;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to go
  clear-last-round
  ask turtles [ partner-up ]                        ;;have turtles try to find a partner
  let partnered-turtles turtles with [ partnered? ]
  ask partnered-turtles [ select-action ]           ;;all partnered turtles select action
  ask partnered-turtles [
    play-a-round
    set num-plays num-plays + 1
  ]
  evolution
  do-scoring
  tick
end

to evolution
  let sum-score 0
  ask turtles [
    if num-plays > 0 [
      set sum-score sum-score + score / num-plays
    ]
  ]
  let average sum-score / count turtles
  ask turtles with [average * num-plays - evolution-stall > score ] [ die ]
  let hatched 0
  ask turtles with [average * num-plays + evolution-stall < score ] [
    set score average * num-plays
    hatch 1 [
      set score 0
      set partnered? false
      set partner nobody
      setxy random-xcor random-ycor
      set num-plays 0
    ]
    set hatched hatched + 1
  ]
  foreach n-values hatched [1] [
    ask turtles [
      set partner-history lput false partner-history
    ]
  ]
end

to clear-last-round
  let partnered-turtles turtles with [ partnered? ]
  ask partnered-turtles [ release-partners ]
end

;;release partner and turn around to leave
to release-partners
  set partnered? false
  set partner nobody
  rt 180
  set label ""
end

;;have turtles try to find a partner
;;Since other turtles that have already executed partner-up may have
;;caused the turtle executing partner-up to be partnered,
;;a check is needed to make sure the calling turtle isn't partnered.

to partner-up ;;turtle procedure
  if (not partnered?) [              ;;make sure still not partnered
    rt (random-float 90 - random-float 90) fd 1     ;;move around randomly
    set partner one-of (turtles-at -1 0) with [ not partnered? ]
    if partner != nobody [              ;;if successful grabbing a partner, partner up
      set partnered? true
      set heading 270                   ;;face partner
      ask partner [
        set partnered? true
        set partner myself
        set heading 90
      ]
    ]
  ]
end

;;choose an action based upon the strategy being played
to select-action ;;turtle procedure
  if strategy = "random" [ act-randomly ]
  if strategy = "cooperate" [ cooperate ]
  if strategy = "defect" [ defect ]
  if strategy = "tit-for-tat" [ tit-for-tat ]
  if strategy = "unforgiving" [ unforgiving ]
  if strategy = "unknown" [ unknown ]
end

to play-a-round ;;turtle procedure
  get-payoff     ;;calculate the payoff for this round
  update-history ;;store the results for next time
end

;;calculate the payoff for this round and
;;display a label with that payoff.
to get-payoff
  set partner-defected? [defect-now?] of partner
  ifelse partner-defected? [
    ifelse defect-now? [
      set score (score + 1) set label 1
    ] [
      set score (score + 0) set label 0
    ]
  ] [
    ifelse defect-now? [
      set score (score + 5) set label 5
    ] [
      set score (score + 3) set label 3
    ]
  ]
end

;;update PARTNER-HISTORY based upon the strategy being played
to update-history
  if strategy = "random" [ act-randomly-history-update ]
  if strategy = "cooperate" [ cooperate-history-update ]
  if strategy = "defect" [ defect-history-update ]
  if strategy = "tit-for-tat" [ tit-for-tat-history-update ]
  if strategy = "unforgiving" [ unforgiving-history-update ]
  if strategy = "unknown" [ unknown-history-update ]
end


;;;;;;;;;;;;;;;;
;;;Strategies;;;
;;;;;;;;;;;;;;;;

;;All the strategies are described in the Info tab.

to act-randomly
  set num-random-games num-random-games + 1
  ifelse (random-float 1.0 < 0.5) [
    set defect-now? false
  ] [
    set defect-now? true
  ]
end

to act-randomly-history-update
;;uses no history- this is just for similarity with the other strategies
end

to cooperate
  set num-cooperate-games num-cooperate-games + 1
  set defect-now? false
end

to cooperate-history-update
;;uses no history- this is just for similarity with the other strategies
end

to defect
  set num-defect-games num-defect-games + 1
  set defect-now? true
end

to defect-history-update
;;uses no history- this is just for similarity with the other strategies
end

to tit-for-tat
  set num-tit-for-tat-games num-tit-for-tat-games + 1
  set partner-defected? item ([who] of partner) partner-history
  ifelse (partner-defected?) [
    set defect-now? true
  ] [
    set defect-now? false
  ]
end

to tit-for-tat-history-update
  set partner-history
    (replace-item ([who] of partner) partner-history partner-defected?)
end

to unforgiving
  set num-unforgiving-games num-unforgiving-games + 1
  set partner-defected? item ([who] of partner) partner-history
  ifelse (partner-defected?)
    [set defect-now? true]
    [set defect-now? false]
end

to unforgiving-history-update
  if partner-defected? [
    set partner-history
      (replace-item ([who] of partner) partner-history partner-defected?)
  ]
end

;;defaults to tit-for-tat
;;can you do better?
to unknown
  let max-strategy "random"
  let max-score random-score / (num-random-games + 1)
  if cooperate-score / (num-cooperate-games + 1) > max-score [
    set max-score cooperate-score / (num-cooperate-games + 1)
    set max-strategy "cooperate"
  ]
  if defect-score / (num-defect-games + 1) > max-score [
    set max-score defect-score / (num-defect-games + 1)
    set max-strategy "defect"
  ]
  if tit-for-tat-score / (num-tit-for-tat-games + 1) > max-score [
    set max-score tit-for-tat-score / (num-tit-for-tat-games + 1)
    set max-strategy "tit-for-tat"
  ]
  if unforgiving-score / (num-unforgiving-games + 1) > max-score [
    set max-score unforgiving-score / (num-unforgiving-games + 1)
    set max-strategy "unforgiving"
  ]
  if max-strategy = "random" [
    act-randomly
    set num-random-games num-random-games - 1
  ]
  if max-strategy = "cooperate" [
    cooperate
    set num-cooperate-games num-cooperate-games - 1
  ]
  if max-strategy = "defect" [
    defect
    set num-defect-games num-defect-games - 1
  ]
  if max-strategy = "tit-for-tat" [
    tit-for-tat
    set num-tit-for-tat-games num-tit-for-tat-games - 1
  ]
  if max-strategy = "unforgiving" [
    unforgiving
    set num-unforgiving-games num-unforgiving-games - 1
  ]

  set num-unknown-games num-unknown-games + 1

  ;set partner-defected? item ([who] of partner) partner-history
  ;ifelse (partner-defected?) [
  ;  set defect-now? true
  ;] [
  ;  set defect-now? false
  ;]
end

;;defaults to tit-for-tat-history-update
;;can you do better?
to unknown-history-update
  set partner-history
    (replace-item ([who] of partner) partner-history partner-defected?)
end


;;;;;;;;;;;;;;;;;;;;;;;;;
;;;Plotting Procedures;;;
;;;;;;;;;;;;;;;;;;;;;;;;;

;;calculate the total scores of each strategy
to do-scoring
  set random-score  (calc-score "random" num-random)
  set cooperate-score  (calc-score "cooperate" num-cooperate)
  set defect-score  (calc-score "defect" num-defect)
  set tit-for-tat-score  (calc-score "tit-for-tat" num-tit-for-tat)
  set unforgiving-score  (calc-score "unforgiving" num-unforgiving)
  set unknown-score  (calc-score "unknown" num-unknown)
end

;; returns the total score for a strategy if any turtles exist that are playing it
to-report calc-score [strategy-type num-with-strategy]
  ifelse num-with-strategy > 0 [
    report (sum [ score ] of (turtles with [ strategy = strategy-type ]))
  ] [
    report 0
  ]
end


; Copyright 2002 Uri Wilensky.
; See Info tab for full copyright and license.
