// [Previous test cases remain the same]

Clarinet.test({
  name: "Cannot register document with invalid hash",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const block = chain.mineBlock([
      Tx.contractCall(
        "docuchain",
        "register-document",
        [
          types.buff(Buffer.from("invalid")), // Invalid hash length
          types.ascii("Test Document"),
          types.ascii("Test Description")
        ],
        wallet_1.address
      ),
    ]);
    assertEquals(block.receipts[0].result, "(err u106)");
  },
});

// [Add more test cases for status updates and history retrieval]
