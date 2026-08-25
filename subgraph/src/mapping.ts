import { Bytes, BigInt } from "@graphprotocol/graph-ts";
import { Registered, BadgeSet } from "../generated/UFSCBuilders/UFSCBuilders";
import { Builder, Board } from "../generated/schema";

const BOARD_ID = Bytes.fromUTF8("board");

export function handleRegistered(event: Registered): void {
  // The event is the only thing an indexer can see. This is why a contract
  // that forgets to emit is invisible to every wallet and explorer on earth.
  let id = event.params.who;
  let b = Builder.load(id);

  if (b == null) {
    b = new Builder(id);
    b.firstSeen = event.block.timestamp;
    b.writes = BigInt.zero();

    let board = Board.load(BOARD_ID);
    if (board == null) {
      board = new Board(BOARD_ID);
      board.total = BigInt.zero();
    }
    board.total = board.total.plus(BigInt.fromI32(1));
    board.save();
  }

  b.name = event.params.name;
  b.token = event.params.token;
  b.updatedAt = event.block.timestamp;
  b.writes = b.writes.plus(BigInt.fromI32(1));
  b.save();
}

export function handleBadgeSet(event: BadgeSet): void {
  // setBadge reverts if you never registered, so the Builder must exist.
  // Still: never assume. An indexer that throws stops indexing everything.
  let b = Builder.load(event.params.who);
  if (b == null) return;

  b.badge = event.params.badge;
  b.updatedAt = event.block.timestamp;
  b.writes = b.writes.plus(BigInt.fromI32(1));
  b.save();
}
