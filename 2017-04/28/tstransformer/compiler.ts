import * as ts from "typescript";

const testTransformer: ts.TransformerFactory<ts.SourceFile> = context => {
    return file => ts.visitEachChild(file, visit, context);
    function visit(node: ts.Node): ts.VisitResult<ts.Node> {
        switch (node.kind) {
            case ts.SyntaxKind.CallExpression:
                return ts.visitEachChild(visitCall(<ts.CallExpression>node), visit, context);
            case ts.SyntaxKind.FunctionDeclaration:
                return visitFunction(<ts.FunctionDeclaration>node);
            default:
                return ts.visitEachChild(node, visit, context);
        }
    }
    function visitCall(node: ts.CallExpression) {
        ts.addSyntheticLeadingComment(node, ts.SyntaxKind.MultiLineCommentTrivia, "@call", /*hasTrailingNewLine*/ false);
        // console.log("node", node.expression.getText());
        // return ts.createIdentifier("HELLO");

        return node;
    }
    function visitFunction(node: ts.FunctionDeclaration) {
        // ts.createFunctionCall(
        ts.addSyntheticLeadingComment(node, ts.SyntaxKind.MultiLineCommentTrivia, "@before", /*hasTrailingNewLine*/ true);
        // console.log("node", node);
        return node;
    }
};

const transformers: ts.CustomTransformers = {
    after: [testTransformer]
}

function compile(fileNames: string[], options: ts.CompilerOptions): void {
    let program = ts.createProgram(fileNames, options);
    let emitResult = program.emit(undefined, undefined, undefined, false, transformers);

    let allDiagnostics = ts.getPreEmitDiagnostics(program).concat(emitResult.diagnostics);

    allDiagnostics.forEach(diagnostic => {
        let { line, character } = diagnostic.file.getLineAndCharacterOfPosition(diagnostic.start);
        let message = ts.flattenDiagnosticMessageText(diagnostic.messageText, '\n');
        console.log(`${diagnostic.file.fileName} (${line + 1},${character + 1}): ${message}`);
    });

    let exitCode = emitResult.emitSkipped ? 1 : 0;
    console.log(`Process exiting with code '${exitCode}'.`);
    process.exit(exitCode);
}

compile(process.argv.slice(2), {
    // noEmitOnError: true, noImplicitAny: true,
    target: ts.ScriptTarget.ES5, module: ts.ModuleKind.CommonJS
});
