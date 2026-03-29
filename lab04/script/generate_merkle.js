import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";
import { getAddress } from "ethers";

// read the list of members
const members = JSON.parse(fs.readFileSync("./members.json", "utf-8"));

// fomat to Checksum (for vm.toString())
// ex: 0xaE1E5002C141D4839D8697D33F3F94cabCBb59eF
const formattedAddresses = members.addresses.map((addr) => getAddress(addr));

// pre-set values for Merkle Tree
const values = formattedAddresses.map((addr) => [addr]);

// build Merkle Tree
const tree = StandardMerkleTree.of(values, ["address"]);
console.log(tree);

const proofs = {}

// build Proofs
for (const [i, v] of tree.entries()) {
  const member = v[0];
  proofs[member] = tree.getProof(i);
}

const output = {
  count: members.count,
  root: tree.root,
  proofs
};

fs.writeFileSync("./merkle-data.json", JSON.stringify(output, null, 2));
console.log("Merkle root:", tree.root);
console.log("Saved to merkle-data.json");