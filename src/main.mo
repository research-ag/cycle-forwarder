import Cycles "mo:base/ExperimentalCycles";
import IC "mo:base/ExperimentalInternetComputer";
import Principal "mo:base/Principal";
import Prim "mo:prim";

actor class (wallet : Text) {
  // See cycle wallet .did file:
  // https://github.com/dfinity/cycles-wallet/blob/main/wallet/src/lib.did
  type Wallet = actor {
    wallet_receive : () -> async ()
  };
  
  type IC = actor {
    deposit_cycles : { canister_id : Principal } -> async ()
  };

  public query func get() : async Nat {
    Cycles.balance();
  };

  // When sweeping we have to hold some cycles back for response reservation
  //   40B for processing 40B instructions
  //   + 2B for 2 MB response size
  //   + epsilon

  // sweep through inter-canister wallet call
  public func sweep(keep : ?Nat) : async Nat {
    let amt : Nat = Cycles.balance() - (switch (keep) {
      case (?x) x * 1_000_000_000;
      case _ 42_105_000_000; // lowest tested value: 42_102_432_000
    });
    let dest : Wallet = actor (wallet);
    await (with cycles = amt) dest.wallet_receive();
    amt
  };

  // sweep through management canister call
  public func sweep2(keep : ?Nat) : async Nat {
    let amt : Nat = Cycles.balance() - (switch (keep) {
      case (?x) x * 1_000_000_000;
      case _ 42_105_000_000; // lowest tested value: 42_102_453_000
    });
    let ic : IC = actor ("aaaaa-aa");
    await (with cycles = amt) ic.deposit_cycles({ canister_id = Principal.fromText(wallet) });
    amt
  };

  // WARNING: depletes the entire cycle balance of the canister
  // 
  // The argument specifies how many cycles are to be kept The value to be kept
  // must be < 40 billion
  public func deplete(keep : Nat64) : async (Nat, Nat64) {
    let burned = Prim.cyclesBurn<system>(Cycles.balance());
    var i = 0;
    var ctr = IC.performanceCounter(0);
    let limit = 40_000_000_000 - 10_000 - keep;
    while (ctr < limit) {
      i += 1;
      ctr := IC.performanceCounter(0);
    };
    (burned, ctr)
  };

  // WARNING: burns as many cycles as possible minus what is specified in the
  // argument.
  // 
  // This does not fully deplete the canister. About 40 billion cycles, who were
  // reserved for execution of this message, will remain.
  public func burn(keep : Nat) : async Nat {
    Prim.cyclesBurn<system>(Cycles.balance() - keep);
  };
}
