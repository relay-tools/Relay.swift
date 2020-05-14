export class RunState {
  private generatedTypes = new Set<string>();
  private generatedTypealiases = false;

  addGeneratedType(name: string) {
    this.generatedTypes.add(name);
  }

  existingGeneratedTypes(): string[] {
    return Array.from(this.generatedTypes);
  }

  hasGeneratedType(name: string): boolean {
    return this.generatedTypes.has(name);
  }

  hasGeneratedTypealiases(): boolean {
    return this.generatedTypealiases;
  }

  setGeneratedTypealiases(flag: boolean) {
    this.generatedTypealiases = flag;
  }

  reset() {
    this.generatedTypes.clear();
    this.generatedTypealiases = false;
  }
}
