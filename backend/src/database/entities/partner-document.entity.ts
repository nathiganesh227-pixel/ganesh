import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

export enum DocumentStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  EXPIRED = 'expired',
}

@Entity('partner_documents')
export class PartnerDocumentEntity {
  @PrimaryColumn()
  id: string;

  @Index()
  @Column()
  partnerId: string;

  @Column()
  documentType: string;

  @Column()
  fileUrl: string;

  @Column()
  fileName: string;

  @Column({ default: 0 })
  fileSize: number;

  @Index()
  @Column({ type: 'varchar', default: DocumentStatus.PENDING })
  status: DocumentStatus;

  @Column({ type: 'text', nullable: true })
  rejectionReason: string;

  @Column()
  submittedAt: Date;

  @Column({ nullable: true })
  reviewedAt: Date;

  @Column({ nullable: true })
  reviewedBy: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
