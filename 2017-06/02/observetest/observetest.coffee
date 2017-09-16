Observable = require 'zen-observable'

ones = Observable.from([1, 2, 3, 4, 5, 6, 7, 8, 9])
tens = Observable.from([10, 20, 30, 40, 50, 60, 70, 80, 90])

async = (obs) ->
  new Observable (observer) ->
    scheduler = Promise.resolve()
    sub = obs.subscribe
      next: (val) ->
        scheduler = scheduler.then ->
          observer.next val
      error: (val) ->
        scheduler = scheduler.then ->
          observer.error val
      complete: ->
        scheduler = scheduler.then ->
          observer.complete()
    -> sub.unsubscribe()

combine = (obsary, f) ->
  obses = new Map()
  toComplete = obsary.length
  new Observable (observer) ->
    subscriptions =
      for obs, i in obsary then do (obs, i) ->
        obs.subscribe
          next: (val) ->
            obses.set obs, val
            observer.next Array.from obses.values()
          error: (err) ->
            observer.error err
          complete: ->
            toComplete--
            observer.complete() if toComplete is 0

    -> sub.unsubscribe() for sub in subscriptions

switcher = ->
  new Observable (observer) ->
    currentSub = null
    {
      switch: (obs) ->
        currentSub?.unsubscribe()
        currentSub = obs.subscribe next: (val) -> observer.next val
      unsubscribe: -> currentSub?.unsubscribe()
    }

module.exports = { ones, tens, combine, switcher, async }