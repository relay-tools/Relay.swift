export class RunState {
  private generatedTypes = new Set<string>();

  addGeneratedType(name: string) {
    this.generatedTypes.add(name);
  }

  hasGeneratedType(name: string): boolean {
    return this.generatedTypes.has(name);
  }

  reset() {
    this.generatedTypes.clear();
  }
}
