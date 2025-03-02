import Cycles "mo:base/ExperimentalCycles";

actor class (wallet : Text) {
  // See cycle wallet .did file:
  // https://github.com/dfinity/cycles-wallet/blob/main/wallet/src/lib.did
  type Wallet = actor {
    wallet_receive : () -> async ()
  };

  public query func get() : async Nat {
    Cycles.balance();
  };
 
  public func sweep(keep : ?Nat) : async Nat {
    let amt : Nat = Cycles.balance() - (switch (keep) {
      case (?x) x * 1_000_000_000;
      case _ 42_500_000_000;
      // lowest tested value: 42_103_000_000
      // it is for response reservation
      // 40B for processing 40B instructions
      // + 2B for 2 MB response size
    });
    Cycles.add<system>(amt);
    let dest : Wallet = actor (wallet);
    await dest.wallet_receive();
    amt
  };
 
};
