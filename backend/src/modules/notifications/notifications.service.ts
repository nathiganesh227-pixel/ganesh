import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotificationEntity } from '../../database/entities/notification.entity';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(NotificationEntity)
    private readonly repo: Repository<NotificationEntity>,
  ) {}

  async findAll(userId = 'user_default'): Promise<NotificationEntity[]> {
    return this.repo.find({ where: { userId } });
  }

  async markAsRead(id: string, userId?: string): Promise<NotificationEntity> {
    const item = await this.repo.findOne({ where: { id } });
    if (!item) throw new NotFoundException(`Notification with ID ${id} not found`);
    if (userId && item.userId && item.userId !== userId) {
      throw new ForbiddenException('You do not have permission to modify this notification');
    }
    item.isRead = true;
    return this.repo.save(item);
  }
}
