// Run this program with:
// $ cat file.t.yaml | deno run test/script/make-test-tree.ts

import { parse } from "jsr:@std/yaml";

type Rule = {
  comment?: string;
  given?: string;
  when?: string;
  and?: Array<Rule>;
  then?: Array<Rule>;
  it?: string;
};

type TreeItem = {
  content: string;
  children: Array<TreeItem>;
  comment?: string;
};

async function main() {
  const content = await readStdinText();
  const tree = parseTestTree(content);
  dedupeNodeNames(tree);

  const strTree = renderTree(tree);
  Deno.stdout.write(new TextEncoder().encode(strTree));
}

function parseTestTree(content: string): TreeItem {
  const data: { [k: string]: Array<Rule> } = parse(content);
  if (!data || typeof data !== "object") {
    throw new Error("The file format is not a valid yaml object");
  }

  const rootKeys = Object.keys(data);
  if (rootKeys.length > 1) {
    throw new Error("The test definition must have only one root node");
  }
  const [rootKey] = rootKeys;
  if (!rootKey || !data[rootKey]) {
    throw new Error("A root node needs to be defined");
  } else if (!data[rootKey]?.length) {
    throw new Error("The root node needs to include at least one element");
  }

  return {
    content: rootKey,
    children: parseRuleChildren(data[rootKey]),
  };
}

function parseRuleChildren(lines: Array<Rule>): Array<TreeItem> {
  if (!lines?.length) return [];

  const result: Array<TreeItem> = lines.map((rule) => {
    if (!rule.when && !rule.given && !rule.it)
      throw new Error("All rules should have a 'given', 'when' or 'it' rule");

    let content = "";
    if (rule.given) {
      content = "Given " + cleanText(rule.given);
    } else if (rule.when) {
      content = "When " + cleanText(rule.when);
    } else if (rule.it) {
      content = "It " + rule.it;
    }

    let children: TreeItem[] = [];
    if (rule.and?.length) {
      children = parseRuleChildren(rule.and);
    } else if (rule.then?.length) {
      children = parseRuleChildren(rule.then);
    }

    const result: TreeItem = {
      content,
      children,
    };

    if (rule.comment) result.comment = rule.comment;
    return result;
  });

  return result;
}

function dedupeNodeNames(
  node: TreeItem,
  seenItems: Set<string> = new Set(),
): Set<string> {
  if (!node.children?.length) return seenItems;

  // If a node has been seen before, append a suffix to it
  for (let i = 0; i < node.children.length; i++) {
    const child = node.children[i];

    let str = child.content.trim();
    if (str.startsWith("It ")) continue;
    else if (seenItems.has(str)) {
      let suffixIdx = 1;
      do {
        suffixIdx++;
        str = child.content.trim() + " " + suffixIdx.toString();
      } while (seenItems.has(str));

      child.content = str;
    }
    seenItems.add(str);

    // Process children
    seenItems = dedupeNodeNames(child, seenItems);
  }
  return seenItems;
}

function renderTree(root: TreeItem): string {
  let result = root.content + "\n";

  for (let i = 0; i < root.children?.length; i++) {
    const item = root.children[i];
    const newLines = renderTreeItem(item, i === root.children.length - 1);
    result += newLines.join("\n") + "\n";
  }

  return result;
}

function renderTreeItem(
  root: TreeItem,
  lastChildren: boolean,
  prefix = "",
): Array<string> {
  const result: string[] = [];

  // Add ourselves
  const content = root.comment
    ? `${root.content} // ${root.comment}`
    : root.content;

  if (lastChildren) {
    result.push(prefix + "└── " + content);
  } else {
    result.push(prefix + "├── " + content);
  }

  // Add any children
  for (let i = 0; i < root.children?.length; i++) {
    const item = root.children[i];

    // Last child
    if (i === root.children?.length - 1) {
      const newPrefix = lastChildren ? prefix + "    " : prefix + "│   ";
      const lines = renderTreeItem(item, true, newPrefix);
      lines.forEach((line) => result.push(line));
      continue;
    }

    // The rest of children
    const newPrefix = lastChildren ? prefix + "    " : prefix + "│   ";
    const lines = renderTreeItem(item, false, newPrefix);
    lines.forEach((line) => result.push(line));
  }

  return result;
}

function cleanText(input: string): string {
  return input.replace(/[^a-zA-Z0-9 ]/g, "").trim();
}

async function readStdinText() {
  let result = "";
  const decoder = new TextDecoder();
  for await (const chunk of Deno.stdin.readable) {
    const text = decoder.decode(chunk);
    result += text;
  }
  return result;
}

if (import.meta.main) {
  main();
}
