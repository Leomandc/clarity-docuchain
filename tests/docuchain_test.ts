import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can register a new document",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const block = chain.mineBlock([
      Tx.contractCall(
        "docuchain",
        "register-document",
        [
          types.buff(Buffer.from("test-hash")),
          types.ascii("Test Document"),
          types.ascii("Test Description")
        ],
        wallet_1.address
      ),
    ]);
    assertEquals(block.receipts.length, 1);
    assertEquals(block.receipts[0].result, "(ok true)");
  },
});

Clarinet.test({
  name: "Cannot register duplicate document",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const block = chain.mineBlock([
      Tx.contractCall(
        "docuchain",
        "register-document",
        [
          types.buff(Buffer.from("test-hash")),
          types.ascii("Test Document"),
          types.ascii("Test Description")
        ],
        wallet_1.address
      ),
      Tx.contractCall(
        "docuchain",
        "register-document",
        [
          types.buff(Buffer.from("test-hash")),
          types.ascii("Test Document"),
          types.ascii("Test Description")
        ],
        wallet_1.address
      ),
    ]);
    assertEquals(block.receipts.length, 2);
    assertEquals(block.receipts[1].result, "(err u101)");
  },
});

Clarinet.test({
  name: "Can verify existing document",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    // Test implementation
  },
});

Clarinet.test({
  name: "Can transfer document ownership",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    // Test implementation
  },
});
