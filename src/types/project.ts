export interface ProjectFile {
  path: string;
  name: string;
  category: string;
  ext: string;
  lines: number;
  bytes: number;
  content: string;
}

export type ActiveTab = 'repository' | 'lwc' | 'model' | 'setup';
